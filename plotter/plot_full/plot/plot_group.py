import os
from statistics import geometric_mean
from typing import List, Dict
import matplotlib.pyplot as plt
import pandas as pd
import seaborn as sns
import itertools
from data_full.csv_reader import CsvReader
import warnings
import sys


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
    sns.set(font_scale=2.3)
    plt.rcParams['font.weight'] = 'bold'
    sns.set_style('ticks')
    nrows = 3
    ncols = 4
    ylim_cap = 2
    fig, axes = plt.subplots(nrows=nrows, ncols=ncols)

    ylim = {
        '2d_switch': [1e10, 0],
        '3d_switch': [1e10, 0],
        '4d_switch': [1e10, 0]
    }

    plot_subplot(dataset=dataset, ax=axes[0][0],
                 topology='2d_switch', optimized_for='Transformer-17B',
                 workloads_run=['Transformer-175B', 'Transformer-1T'],
                 ylim_cap=ylim_cap, ylim=ylim)
    plot_subplot(dataset=dataset, ax=axes[0][1],
                 topology='2d_switch', optimized_for='Transformer-175B',
                 workloads_run=['Transformer-17B', 'Transformer-1T'],
                 ylim_cap=ylim_cap, ylim=ylim)
    plot_subplot(dataset=dataset, ax=axes[0][2],
                 topology='2d_switch', optimized_for='Transformer-1T',
                 workloads_run=['Transformer-17B', 'Transformer-175B'],
                 ylim_cap=ylim_cap, ylim=ylim)
    plot_subplot(dataset=dataset, ax=axes[0][3],
                 topology='2d_switch', optimized_for='Group',
                 workloads_run=['Transformer-17B', 'Transformer-175B', 'Transformer-1T'],
                 ylim_cap=ylim_cap, ylim=ylim)

    plot_subplot(dataset=dataset, ax=axes[1][0],
                 topology='3d_switch', optimized_for='Transformer-17B',
                 workloads_run=['Transformer-175B', 'Transformer-1T'],
                 ylim_cap=ylim_cap, ylim=ylim)
    plot_subplot(dataset=dataset, ax=axes[1][1],
                 topology='3d_switch', optimized_for='Transformer-175B',
                 workloads_run=['Transformer-17B', 'Transformer-1T'],
                 ylim_cap=ylim_cap, ylim=ylim)
    plot_subplot(dataset=dataset, ax=axes[1][2],
                 topology='3d_switch', optimized_for='Transformer-1T',
                 workloads_run=['Transformer-17B', 'Transformer-175B'],
                 ylim_cap=ylim_cap, ylim=ylim)
    plot_subplot(dataset=dataset, ax=axes[1][3],
                 topology='3d_switch', optimized_for='Group',
                 workloads_run=['Transformer-17B', 'Transformer-175B', 'Transformer-1T'],
                 ylim_cap=ylim_cap, ylim=ylim)

    plot_subplot(dataset=dataset, ax=axes[2][0],
                 topology='4d_switch', optimized_for='Transformer-17B',
                 workloads_run=['Transformer-175B', 'Transformer-1T'],
                 ylim_cap=ylim_cap, ylim=ylim)
    plot_subplot(dataset=dataset, ax=axes[2][1],
                 topology='4d_switch', optimized_for='Transformer-175B',
                 workloads_run=['Transformer-17B', 'Transformer-1T'],
                 ylim_cap=ylim_cap, ylim=ylim)
    plot_subplot(dataset=dataset, ax=axes[2][2],
                 topology='4d_switch', optimized_for='Transformer-1T',
                 workloads_run=['Transformer-17B', 'Transformer-175B'],
                 ylim_cap=ylim_cap, ylim=ylim)
    plot_subplot(dataset=dataset, ax=axes[2][3],
                 topology='4d_switch', optimized_for='Group',
                 workloads_run=['Transformer-17B', 'Transformer-175B', 'Transformer-1T'],
                 ylim_cap=ylim_cap, ylim=ylim)

    for i in range(nrows):
        topology = f"{i + 2}d_switch"
        max_value = min(ylim[topology][1], ylim_cap)  # capped

        min_value = ylim[topology][0]
        margin = (max_value - min_value) * 0.1

        for j in range(ncols):
            axes[i][j].set_ylim((min_value - margin), (max_value + margin))

    handles, labels = axes[0][0].get_legend_handles_labels()
    handles = [handles[2], handles[1], handles[3], handles[0]]
    labels = [labels[2], labels[1], labels[3], labels[0]]
    fig.legend(handles=handles, labels=labels,
               # bbox_to_anchor=(0.5, 0.085),
               bbox_to_anchor=(0.5, 0.105),
               loc="upper center", ncol=4,
               columnspacing=1,
               markerscale=3)

    for i in range(nrows):
        for j in range(1, ncols):
            axes[i][j].set_yticklabels('')

    for i in range(nrows - 1):
        for j in range(ncols):
            axes[i][j].set_xticklabels('')

    for i in range(ncols):
        axes[-1][i].set_xlabel("BW/NPU (GB/s)", weight='bold')

    axes[1][0].set_ylabel("Slowdown over Optimized", weight='bold', labelpad=15)

    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    fig.set_size_inches((16, 8))
    fig.tight_layout(rect=[-0.02, 0.035, 1, 1.02], h_pad=0.3, w_pad=0)
    fig.subplots_adjust(wspace=0.1, hspace=0.35)
    fig.savefig(os.path.join(output_dir, 'fig15.pdf'))
    fig.clf()
    plt.close(fig=fig)

    print("Fig 15 (Full) plotting finished.")


def plot_subplot(dataset: pd.DataFrame, ax,
                 topology: str, optimized_for: str, ylim_cap: float, 
                 workloads_run: List[str],
                 ylim: Dict[str, List[float]]):
    # setting
    markers = True
    markersize = 15
    solid_line_width = 8
    dashed_line_width = 4

    # process data
    top_data = dataset.loc[dataset['Topology'] == topology]

    plot_data = pd.DataFrame()

    for target_workload in workloads_run:
        baseline = top_data.loc[top_data['BWTarget'] == target_workload]
        baseline = baseline.loc[baseline['Workload'] == target_workload]

        data = top_data.loc[top_data['BWTarget'] == optimized_for]
        data = data.loc[data['Workload'] == target_workload]

        for index, row in data.iterrows():
            bw = row['BW']
            baseline_time = baseline.loc[baseline['BW'] == bw]['CommsTime'].item()

            plot_data = plot_data.append({
                'Workload': target_workload,
                'BW': bw,
                'Speedup': row['CommsTime'] / baseline_time,
                'Feasible': row['Feasible']
            }, ignore_index=True)

    # compute geomean
    for bw in range(100, 1001, 100):
        rows = plot_data.loc[plot_data['BW'] == bw]
        geomean_data = rows['Speedup'].tolist()
        geomean_data.append(1)

        plot_data = plot_data.append({
            'Workload': 'Mean',
            'BW': bw,
            'Speedup': geometric_mean(geomean_data),
            'Feasible': rows.iloc[0]['Feasible']
        }, ignore_index=True)

    min_value = min(plot_data['Speedup'])
    if min_value < ylim[topology][0]:
        ylim[topology][0] = min_value

    max_value = max(plot_data['Speedup'])
    if max_value > ylim[topology][1]:
        ylim[topology][1] = max_value

    if optimized_for != 'Group':
        for bw in range(100, 1001, 100):
            plot_data = plot_data.append({
                'Workload': optimized_for,
                'BW': bw,
                'Speedup': 0,  # not showing up in the plot, to show, set this to 1
                'Feasible': 'yes'
            }, ignore_index=True)

    plot_data.sort_values(by='Workload', ascending=True, inplace=True)
    plot_data.reset_index(drop=True, inplace=True)

    plot_data_solid = plot_data.loc[plot_data['Feasible'] == 'yes']

    plot_data_dashed = plot_data.loc[plot_data['Feasible'] == 'no']
    for workload in plot_data_dashed['Workload'].unique():
        search_bw = min(plot_data_dashed.loc[plot_data_dashed['Workload'] == workload]['BW']) - 100

        if search_bw >= 100:
            search_data = plot_data.loc[plot_data['Workload'] == workload]
            found_row = search_data.loc[search_data['BW'] == search_bw]
            plot_data_dashed = plot_data_dashed.append(found_row)

    workload_used = plot_data_dashed['Workload'].unique()
    for workload in plot_data['Workload'].unique():
        if workload not in workload_used:
            plot_data_dashed = plot_data_dashed.append({
                'Workload': optimized_for,
                'BW': 100,
                'Speedup': -100,  # not showing up in the plot, to show, set this to 1
                'Feasible': 'yes'
            }, ignore_index=True)
    plot_data_dashed = plot_data_dashed.sort_values(by='Workload', ascending=True)

    sns.lineplot(data=plot_data_dashed, ax=ax,
                 x='BW', y='Speedup',
                 hue='Workload', style='Workload', linestyle='--',
                 markers=markers, markersize=markersize,
                 dashes=False, linewidth=dashed_line_width)

    sns.lineplot(data=plot_data_solid, ax=ax,
                 x='BW', y='Speedup',
                 hue='Workload', style='Workload', linestyle='-',
                 markers=markers, markersize=markersize,
                 dashes=False, linewidth=solid_line_width)

    # annotate number if over 2
    for index, row in plot_data.iterrows():
        if row['Speedup'] > (ylim_cap + 0.1):
            ax.annotate(f"{row['Speedup']:.1f}",  # this is the text
                        (row['BW'], 1.7),  # these are the coordinates to position the label
                        textcoords="offset points",  # how to position the text
                        xytext=(0, 0),  # distance from text to points (x,y)
                        ha='center',
                        rotation=-90)  # horizontal alignment can be left, right or center

    topology_title = topology.split('_')[0].upper()
    if optimized_for == 'Group':
        ax.set_title(f"{topology_title}_{optimized_for}OptBW", weight='bold')
    else:
        parameter_size = optimized_for.split('-')[1]
        ax.set_title(f"{topology_title}_T-{parameter_size}", weight='bold')

    ax.set_xlabel("")
    ax.set_ylabel("")

    ax.get_legend().remove()

    ax.set_xticks(range(100, 1001, 100))
    ax.set_xticklabels(['', '200', '', '400', '', '600', '', '800', '', '1000'])


if __name__ == '__main__':
    plot_workload()
