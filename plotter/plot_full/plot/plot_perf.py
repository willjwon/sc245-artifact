from data_full.csv_reader import CsvReader
from typing import Dict, List
from statistics import geometric_mean
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
    dataset = csv_reader.update_cost(dataset=dataset)
    csv_reader.check_topology_feasibility(dataset=dataset)
    dataset = csv_reader.filter_target_bw(dataset=dataset)
    dataset.reset_index(drop=True, inplace=True)

    # start plotting
    sns.set(font_scale=2.3)
    plt.rcParams['font.weight'] = 'bold'
    sns.set_style('ticks')
    nrows = 3
    ncols = 3
    fig, axes = plt.subplots(nrows=nrows, ncols=ncols)

    ylim = {
        '2d_switch': [1e10, 0],
        '3d_switch': [1e10, 0],
        '4d_switch': [1e10, 0]
    }

    # dim-major
    plot_subplot(dataset=dataset, ax=axes[0][0],
                 topology='2d_switch', workload='Transformer-17B',
                 ylim=ylim)
    plot_subplot(dataset=dataset, ax=axes[0][1],
                 topology='2d_switch', workload='Transformer-175B',
                 ylim=ylim)
    plot_subplot(dataset=dataset, ax=axes[0][2],
                 topology='2d_switch', workload='Transformer-1T',
                 ylim=ylim)

    plot_subplot(dataset=dataset, ax=axes[1][0],
                 topology='3d_switch', workload='Transformer-17B',
                 ylim=ylim)
    plot_subplot(dataset=dataset, ax=axes[1][1],
                 topology='3d_switch', workload='Transformer-175B',
                 ylim=ylim)
    plot_subplot(dataset=dataset, ax=axes[1][2],
                 topology='3d_switch', workload='Transformer-1T',
                 ylim=ylim)

    plot_subplot(dataset=dataset, ax=axes[2][0],
                 topology='4d_switch', workload='Transformer-17B',
                 ylim=ylim)
    plot_subplot(dataset=dataset, ax=axes[2][1],
                 topology='4d_switch', workload='Transformer-175B',
                 ylim=ylim)
    plot_subplot(dataset=dataset, ax=axes[2][2],
                 topology='4d_switch', workload='Transformer-1T',
                 ylim=ylim)

    for i in range(nrows):
        topology = f'{i + 2}d_switch'
        min_value = ylim[topology][0]
        max_value = ylim[topology][1]

        margin = (max_value - min_value) * 0.1
        for j in range(ncols):
            axes[i][j].set_ylim(min_value - margin, max_value + margin)

    handles, labels = axes[0][0].get_legend_handles_labels()
    handles = handles[:3] + handles[-1:]
    labels = labels[:3] + labels[-1:]
    # handles = handles[:3]
    # labels = labels[:3]
    fig.legend(handles=handles, labels=labels,
               bbox_to_anchor=(0.5, 0.105),
               loc="upper center", ncol=4,
               columnspacing=1,
               markerscale=2)

    for i in range(nrows):
        for j in range(1, ncols):
            axes[i][j].set_yticklabels(labels='')

    for i in range(nrows - 1):
        for j in range(ncols):
            axes[i][j].set_xticklabels('')

    for i in range(ncols):
        axes[-1][i].set_xlabel("BW/NPU (GB/s)", weight='bold')

    axes[1][0].set_ylabel("Speedup over 2D EqualBW", weight='bold', labelpad=20)

    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    fig.set_size_inches((14, 8))
    fig.tight_layout(rect=[-0.02, 0.035, 1, 1.02], h_pad=0.3, w_pad=0)
    fig.subplots_adjust(wspace=0.1, hspace=0.35)
    fig.savefig(os.path.join(output_dir, "fig12.pdf"))
    fig.clf()
    plt.close(fig=fig)

    print("Fig 12 (Full) plotting finished.")


def plot_subplot(dataset: pd.DataFrame, ax, topology: str, workload: str,
                 ylim: Dict[str, List[float]]):
    # setting
    markers = True
    markersize = 15
    dgx_marker_size = 15
    solid_line_width = 8
    dashed_line_width = 4

    # filter data
    # baseline = dataset.loc[dataset['Topology'] == topology]
    baseline = dataset.loc[dataset['Topology'] == '2d_switch']
    baseline = baseline.loc[baseline['Workload'] == workload]
    baseline = baseline.loc[baseline['BWAllocation'] == 'EqualBW']

    dgx = dataset.loc[dataset['BWAllocation'] == 'DGX-like']
    dgx = dgx.loc[dgx['Workload'] == workload]
    dgx.reset_index(drop=True, inplace=True)

    data = dataset.loc[dataset['Topology'] == topology]
    data = data.loc[data['Workload'] == workload]
    data = data.loc[~data['BWAllocation'].str.contains('DGX')]

    plot_data = pd.DataFrame()

    for index, row in data.iterrows():
        bw = row['BW']
        if bw % 100 != 0:
            continue

        baseline_time = baseline.loc[baseline['BW'] == bw]['CommsTime'].item()
        speedup = baseline_time / row['CommsTime']

        plot_data = plot_data.append({
            'BW': bw,
            'BWAllocation': row['BWAllocation'],
            'Speedup': speedup,
            'Feasible': row['Feasible']
        }, ignore_index=True)

    plot_data.sort_values(by='BWAllocation', ascending=True, inplace=True)
    plot_data.reset_index(drop=True, inplace=True)

    plot_data_solid = plot_data.loc[plot_data['Feasible'] == 'yes']
    plot_data_dashed = plot_data.loc[plot_data['Feasible'] == 'no']

    for bw_allocation in plot_data_dashed['BWAllocation'].unique():
        search_bw = min(plot_data_dashed.loc[plot_data_dashed['BWAllocation'] == bw_allocation]['BW']) - 100

        if search_bw >= 100:
            search_data = plot_data.loc[plot_data['BWAllocation'] == bw_allocation]
            found_row = search_data.loc[search_data['BW'] == search_bw]
            plot_data_dashed = plot_data_dashed.append(found_row)

    bw_allocation_used = plot_data_dashed['BWAllocation'].unique()
    for bw_allocation in plot_data['BWAllocation'].unique():
        if bw_allocation not in bw_allocation_used:
            plot_data_dashed = plot_data_dashed.append({
                'BW': 100,
                'BWAllocation': bw_allocation,
                'Speedup': 0,
                'Feasible': 'no'
            }, ignore_index=True)
    plot_data_dashed = plot_data_dashed.sort_values(by='BWAllocation', ascending=True)

    sns.lineplot(data=plot_data_dashed, ax=ax,
                 x='BW', y='Speedup',
                 hue='BWAllocation', style='BWAllocation', linestyle='--',
                 markers=markers, markersize=markersize,
                 dashes=False, linewidth=dashed_line_width)

    sns.lineplot(data=plot_data_solid, ax=ax,
                 x='BW', y='Speedup',
                 hue='BWAllocation', style='BWAllocation', linestyle='-',
                 markers=markers, markersize=markersize,
                 dashes=False, linewidth=solid_line_width)

    if len(dgx) > 0:
        bw = dgx.loc[0, 'BW'].item()
        baseline_time = baseline.loc[baseline['BW'] == bw]['CommsTime'].item()
        speedup = baseline_time / dgx.loc[0, 'CommsTime'].item()

        ax.plot(bw, speedup, linestyle='', marker="o", markersize=dgx_marker_size,
                markerfacecolor="red", markeredgecolor="red",
                label="DGX-like")

    min_value = min(plot_data['Speedup'])
    if min_value < ylim[topology][0]:
        ylim[topology][0] = min_value

    max_value = max(plot_data['Speedup'])
    if max_value > ylim[topology][1]:
        ylim[topology][1] = max_value

    topology_title = topology.split('_')[0].upper()
    workload_title = f"T-{workload.split('-')[1]}"
    ax.set_title(f"{workload_title} + {topology_title}", weight='bold')
    ax.set_xlabel("")
    ax.set_ylabel("")
    ax.get_legend().remove()

    ax.set_xticks(range(100, 1001, 100))
    ax.set_xticklabels(['', '200', '', '400', '', '600', '', '800', '', '1000'])


if __name__ == '__main__':
    plot_workload()
