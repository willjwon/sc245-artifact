"""
This source code is licensed under the MIT license found in the
LICENSE file in the root directory of this source tree.
"""

import os
import numpy as np
import pandas as pd


class CsvReader:
    def __init__(self, dir: str = '../../result/'):
        self.dir = dir
        self.filename_to_load = "backend_end_to_end.csv"

    @staticmethod
    def filter_target_bw(dataset: pd.DataFrame) -> pd.DataFrame:
        result = pd.DataFrame()

        for index, row in dataset.iterrows():
            if row['BWAllocation'] == 'PerfOptBW':
                if row['BWTarget'] == row['Workload']:
                    result = result.append(row)
            else:
                result = result.append(row)

        result.reset_index(drop=True, inplace=True)
        return result

    @staticmethod
    def parse_run_name(dataset: pd.DataFrame) -> None:
        """
        Parse run_name inside a dataset.

        :param dataset: dataset to split RunName into
        """
        # "${CONFIG_NAME}-${workload}-${NETWORK[${i}]}-${SYSTEM[${i}]}-${comm_scale}-${UNITS_COUNT[${i}]}-${LINKS_COUNT[${i}]}-${LINK_BANDWIDTH[${i}]}-${NUM_PASSES}"
        # split run name
        run_name_split = dataset['RunName'].str.split('-').str

        # create rows as required
        try:
            dataset['RunName'] = run_name_split[0]
            dataset['Workload'] = run_name_split[1].str.split('.').str[0]
            dataset['Topology'] = run_name_split[2].str.split('.').str[0]
            dataset['System'] = run_name_split[3].str.split('.').str[0]
            dataset['CommScale'] = run_name_split[4].astype(int)
            dataset['CommScale'] = run_name_split[5].astype(float)
            dataset['UnitsCount'] = run_name_split[6].str.replace(" ", "_")
            dataset['LinksCount'] = run_name_split[7].str.replace(" ", "_")
            dataset['LinkBandwidths'] = run_name_split[8].str.replace(" ", "_")
            dataset['Passes'] = run_name_split[9].astype(int)
        except ValueError:
            dataset['RunName'] = run_name_split[0]
            dataset['Workload'] = run_name_split[1].str.split('.').str[0]
            dataset['Topology'] = run_name_split[2].str.split('.').str[0]
            dataset['System'] = run_name_split[3].str.split('.').str[0]
            dataset['CommScale'] = run_name_split[4].astype(int)
            dataset['CommScale'] = -1
            dataset['UnitsCount'] = run_name_split[5].str.replace(" ", "_")
            dataset['LinksCount'] = run_name_split[6].str.replace(" ", "_")
            dataset['LinkBandwidths'] = run_name_split[7].str.replace(" ", "_")
            dataset['Passes'] = run_name_split[8].astype(int)

        # add new columns
        dataset['NPUsCount'] = [np.prod(list(map(int, uc))) for uc in dataset['UnitsCount'].str.split('_')]
        dataset['PhysicalTopology'] = dataset['Topology'] + " (" + dataset['UnitsCount'] + ')'

        # updated exposed commsTime
        dataset['ExposedCommsTime'] = dataset['CommsTime'] - dataset['ComputeTime']

        for index, row in dataset.iterrows():
            links_count = np.array(row['LinksCount'].split('_'), dtype=int)
            link_bandwidths = np.array(row['LinkBandwidths'].split('_'), dtype=float)
            dataset.loc[index, 'BW'] = round(sum(links_count * link_bandwidths))

            if 'group' in row['RunName']:
                dataset.loc[index, 'BWTarget'] = 'Group'
            elif '17b' in row['RunName']:
                dataset.loc[index, 'BWTarget'] = 'Transformer-17B'
            elif '175b' in row['RunName']:
                dataset.loc[index, 'BWTarget'] = 'Transformer-175B'
            elif '1t' in row['RunName']:
                dataset.loc[index, 'BWTarget'] = 'Transformer-1T'
            else:
                dataset.loc[index, 'BWTarget'] = 'No'

        dataset['BW'] = dataset['BW'].astype(int)

    @staticmethod
    def parse_loop(dataset):
        for index, row in dataset.iterrows():
            if 'noo' in row['RunName']:
                dataset.loc[index, 'LoopTarget'] = 'NoOverlap'
            elif 'overlap' in row['RunName']:
                dataset.loc[index, 'LoopTarget'] = 'Overlap'
            elif 'group' in row['RunName']:
                dataset.loc[index, 'LoopTarget'] = 'GroupOpt'

            if 'top' in row['RunName']:
                dataset.loc[index, 'RunOn'] = 'Overlap'
            elif 'will' in row['RunName']:
                dataset.loc[index, 'RunOn'] = 'NoOverlap'

        return dataset

    @staticmethod
    def update_cost(dataset: pd.DataFrame) -> pd.DataFrame:
        cost_dataset = dataset.loc[dataset['Workload'] == 'Cost']
        perf_dataset = dataset.loc[dataset['Workload'] != 'Cost'].copy()

        for index, row in perf_dataset.iterrows():
            if 'dgx' in row['RunName']:
                continue

            topology = row['Topology'].split('_')[0]
            alloc = row['BWAllocation']
            bandwidth = row['BW']
            target = row['BWTarget']

            search = cost_dataset.loc[cost_dataset['Topology'] == topology]
            search = search.loc[search['BWAllocation'] == alloc]
            search = search.loc[search['BW'] == bandwidth]
            search = search.loc[search['BWTarget'] == target]

            search_cost = search['Cost'].item()
            perf_dataset.loc[index, 'Cost'] = search_cost

        return perf_dataset

    @staticmethod
    def parse_bw_allocation_strategy(dataset: pd.DataFrame) -> None:
        for index, row in dataset.iterrows():
            if '_equal' in row['RunName']:
                dataset.loc[index, 'BWAllocation'] = 'EqualBW'
            elif 'dgx' in row['RunName']:
                dataset.loc[index, 'BWAllocation'] = 'DGX-like'
            elif '_perf_' in row['RunName']:
                dataset.loc[index, 'BWAllocation'] = 'PerfOptBW'
            elif '_perfcost_' in row['RunName']:
                dataset.loc[index, 'BWAllocation'] = 'PerfPerCostOptBW'
            else:
                print('BW Allocation Scheme Unknown.')
                exit(-1)

    def read_csv(self) -> pd.DataFrame:
        """
        Load dataset

        :return: pd.DataFrame with loaded dataset
        """

        # dataframe to fill up
        dataset = pd.DataFrame()

        # iterate recursively inside self.dir to find files
        for dirpath, _, filenames in os.walk(top=self.dir):
            for filename in filenames:
                if filename != self.filename_to_load:
                    continue

                # matching file found: load and parse
                # load file
                file_path = os.path.join(dirpath, filename)
                load_dataset = pd.read_csv(file_path)

                # parse dataset
                load_dataset.dropna(how='all', inplace=True)
                self.parse_run_name(dataset=load_dataset)

                # merge this dataset
                dataset = pd.concat([dataset, load_dataset])

        # reset index
        dataset.reset_index(drop=True, inplace=True)

        return dataset

    @staticmethod
    def compute_all_reduce_bw_utilization(dataset: pd.DataFrame) -> None:
        for index, row in dataset.iterrows():
            # get total available BW budget
            links = np.array(row['LinksCount'].split('_'), dtype=float)
            bandwidths = np.array(row['LinkBandwidths'].split('_'), dtype=float)
            total_bw = np.sum(links * bandwidths) * 1024  # MB/s

            # compute bw utilization
            collective_time_optimal = (row['TotalPayloadSize'] / total_bw) * 1e6  # time in us
            bw_utilization = collective_time_optimal / row['CommsTime']
            dataset.loc[index, 'BwUtilization'] = bw_utilization * 100  # in percentage

    @staticmethod
    def parse_workload_name(dataset: pd.DataFrame) -> None:
        for index, row in dataset.iterrows():
            if row['Workload'] == 'transformer_17B':
                dataset.loc[index, 'Workload'] = "Transformer-17B"
            elif row['Workload'] == 'transformer_175B':
                dataset.loc[index, 'Workload'] = "Transformer-175B"
            elif row['Workload'] == 'transformer_1T':
                dataset.loc[index, 'Workload'] = "Transformer-1T"
            elif row['Workload'] == 'microAllReduce':
                dataset.loc[index, 'Workload'] = "Cost"
            else:
                assert False, "Workload name"
                exit(-1)

    @staticmethod
    def check_topology_feasibility(dataset: pd.DataFrame) -> None:
        # Network feasibility
        inter_tile_limit = 700
        inter_package_limit = 400
        inter_node_limit = 160
        inter_pod_limit = 100

        # (inter-package + inter-node) <= 350 GB/s
        # scale_up_limit = 560

        for index, row in dataset.iterrows():
            bws = [float(bw) for bw in row['LinkBandwidths'].split('_')]
            links = [float(l) for l in row['LinksCount'].split('_')]
            bandwidths = list()
            for i in range(len(bws)):
                bandwidths.append(bws[i] * links[i])

            feasible = True

            # check infeasible cases
            if len(bandwidths) == 2:
                if bandwidths[0] > inter_package_limit:
                    feasible = False
                if bandwidths[1] > inter_pod_limit:
                    feasible = False
            elif len(bandwidths) == 3:
                if bandwidths[0] > inter_package_limit:
                    feasible = False
                if bandwidths[1] > inter_node_limit:
                    feasible = False
                if bandwidths[2] > inter_pod_limit:
                    feasible = False
            elif len(bandwidths) == 4:
                if bandwidths[0] > inter_tile_limit:
                    feasible = False
                if bandwidths[1] > inter_package_limit:
                    feasible = False
                if bandwidths[2] > inter_node_limit:
                    feasible = False
                if bandwidths[3] > inter_pod_limit:
                    feasible = False
            else:
                print(f"[Feasibility] given network dimension is {len(bandwidths)}.")
                exit(-1)

            # save feasibility
            if feasible:
                dataset.loc[index, 'Feasible'] = 'yes'
            else:
                dataset.loc[index, 'Feasible'] = 'no'
