from data_small.csv_reader import CsvReader
from typing import Dict, List
import os
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import sys
import warnings


def plot_workload():
    # ignore pandas warnings
    warnings.filterwarnings('ignore')

    # parse argument
    result_dir = sys.argv[1]
    output_dir = sys.argv[2]

    # read dataset
    csv_reader = CsvReader(dir=result_dir)
    dataset = csv_reader.read_csv()
    csv_reader.parse_workload_name(dataset=dataset)

    # process dataset
    csv_reader.parse_bw_allocation_strategy(dataset=dataset)
    csv_reader.check_topology_feasibility(dataset=dataset)
    dataset.reset_index(drop=True, inplace=True)

    # start plotting
    sns.set(font_scale=2)
    plt.rcParams['font.weight'] = 'bold'
    sns.set_style('ticks')
    fig, ax = plt.subplots(nrows=1, ncols=1)

    # plot
    plot_subplot(dataset=dataset, ax=ax)

    # aesthetics
    handles, labels = ax.get_legend_handles_labels()
    handles = handles[:3] + handles[-1:]
    labels = labels[:3] + labels[-1:]
    legend = ax.legend(handles=handles, labels=labels,
                       loc="upper center", ncol=2,
                       bbox_to_anchor=(0.5, -0.19),
                       columnspacing=1,
                       markerscale=3)
    legend.legendHandles[-1].set_markersize(20)

    # save graph
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    fig.set_size_inches((9, 6))
    fig.tight_layout(rect=[0, -0.07, 1, 1.03], h_pad=0, w_pad=0)

    fig.savefig(os.path.join(output_dir, 'fig14.pdf'))
    fig.clf()
    plt.close(fig=fig)

    print("Fig 14 (Small) plotting finished.")


def plot_subplot(dataset: pd.DataFrame, ax):
    # setting
    markers = True
    markersize = 25
    dgx_marker_size = 25
    solid_line_width = 10
    dashed_line_width = 6

    # filter data
    baseline = dataset.loc[dataset['BWAllocation'] == 'EqualBW']

    dgx = dataset.loc[dataset['BWAllocation'] == 'DGX-like']
    dgx.reset_index(drop=True, inplace=True)

    data = dataset.loc[~dataset['BWAllocation'].str.contains('DGX')]

    # compute perf/cost
    baseline_row = baseline.loc[baseline['BW'] == 100]
    baseline_speed = baseline_row['CommsTime'].item()
    baseline_cost = baseline_row['Cost'].item()

    baseline['Speedup'] = baseline_speed / baseline['CommsTime']
    baseline['Costup'] = baseline['Cost'] / baseline_cost
    baseline['PerfCost'] = baseline['Speedup'] / baseline['Costup']

    data['Speedup'] = baseline_speed / data['CommsTime']
    data['Costup'] = data['Cost'] / baseline_cost
    data['PerfCost'] = data['Speedup'] / data['Costup']
    
    if len(dgx) > 0:
        dgx['Speedup'] = baseline_speed / dgx['CommsTime']
        dgx['Costup'] = dgx['Cost'] / baseline_cost
        dgx['PerfCost'] = dgx['Speedup'] / dgx['Costup']

    plot_data = pd.DataFrame()

    for index, row in data.iterrows():
        bw = row['BW']
        if bw % 100 != 0:
            continue

        baseline_perf_cost = baseline.loc[baseline['BW'] == bw]['PerfCost'].item()
        perf_cost_up = row['PerfCost'] / baseline_perf_cost

        new_row = pd.DataFrame({
            'BW': [bw],
            'BWAllocation': [row['BWAllocation']],
            'PerfCostUp': [perf_cost_up],
            'Feasible': [row['Feasible']]
        })
        plot_data = pd.concat([plot_data, new_row])
    plot_data.sort_values(by='BWAllocation', ascending=True, inplace=True)
    plot_data.reset_index(drop=True, inplace=True)

    plot_data_solid = plot_data.loc[plot_data['Feasible'] == 'yes']

    plot_data_dashed = plot_data.loc[plot_data['Feasible'] == 'no']
    for bw_allocation in plot_data_dashed['BWAllocation'].unique():
        search_bw = min(plot_data_dashed.loc[plot_data_dashed['BWAllocation'] == bw_allocation]['BW']) - 100

        if search_bw >= 100:
            search_data = plot_data.loc[plot_data['BWAllocation'] == bw_allocation]
            found_row = search_data.loc[search_data['BW'] == search_bw]
            plot_data_dashed = pd.concat([plot_data_dashed, found_row])

    bw_allocation_used = plot_data_dashed['BWAllocation'].unique()
    for bw_allocation in plot_data['BWAllocation'].unique():
        if bw_allocation not in bw_allocation_used:
            new_row = pd.DataFrame({
                'BW': [100],
                'BWAllocation': [bw_allocation],
                'PerfCostUp': [-100],
                'Feasible': ['no']
            })
            plot_data_dashed = pd.concat([plot_data_dashed, new_row])
    plot_data_dashed = plot_data_dashed.sort_values(by='BWAllocation', ascending=True)

    sns.lineplot(data=plot_data_dashed, ax=ax,
                 x='BW', y='PerfCostUp',
                 hue='BWAllocation', style='BWAllocation', linestyle='--',
                 markers=markers, markersize=markersize,
                 dashes=False, linewidth=dashed_line_width)

    sns.lineplot(data=plot_data_solid, ax=ax,
                 x='BW', y='PerfCostUp',
                 hue='BWAllocation', style='BWAllocation', linestyle='-',
                 markers=markers, markersize=markersize,
                 dashes=False, linewidth=solid_line_width)

    if len(dgx) > 0:
        bw = dgx.loc[0, 'BW'].item()
        baseline_perf_cost = baseline.loc[baseline['BW'] == bw]['PerfCost'].item()
        dgx_perf_cost = dgx.loc[0, 'PerfCost'].item() / baseline_perf_cost
        ax.plot(bw, dgx_perf_cost, linestyle='', marker="o", markersize=dgx_marker_size,
                markerfacecolor="red", markeredgecolor="red",
                label="DGX-like")

    ax.set_title("T-17B + 2D", weight='bold')
    ax.set_xlabel("BW/NPU (GB/s)", weight='bold')
    ax.set_ylabel("Normalized Perf./Cost", weight='bold')
    ax.get_legend().remove()

    ax.set_xticks(range(100, 1001, 100))
    ax.set_xticklabels(['', '200', '', '400', '', '600', '', '800', '', '1000'])


if __name__ == '__main__':
    plot_workload()
