# sc245-artifact
Docker Image for AD/AE Process of SC Paper 245

# Installing Docker Image
## Pulling from Docker Hub
You can pull the image directly from the Docker Hub.
```bash
docker pull willjwon/sc245-artifact
docker tag willjwon/sc245-artifact sc245-artifact
```

## Building Locally
Rather, you can also clone this repo and build the Docker image locally.
```bash
git clone https://github.com/willjwon/sc245-artifact.git
cd sc245-artifact
docker build -t sc245-artifact .
```

# Running Network BW Optimization Framework
We provide `optimize.sh` script to run this. The basic syntax is as follows.
```bash
docker run sc245-artifact optimize.sh <NetworkDim> <BW> <Workload> <Target> <TrainingLoop>
```
Possible options are listed here (all options are case-sensitive):
- NetworkDim: `2D`, `3D`, `4D`
- BW: `int` number, network BW/NPU budget.
- Workload: `17B`, `175B`, `1T`
- Target: `Perf`, `PerfPerCost`
- TrainingLoop: `NoOverlap`, `Overlap`

Once invoked, the optimizer tries to optimize the network BW distribution under the given setup. You can run this until the BW allocation saturates.

## Reproducing Table VI
In order to reproduce Table VI, You can go through optimizationb of four configurations.
```bash
docker run sc245-artifact optimize.sh 4D 325 175B Perf NoOverlap
docker run sc245-artifact optimize.sh 4D 325 175B Perf Overlap
docker run sc245-artifact optimize.sh 4D 325 1T Perf NoOverlap
docker run sc245-artifact optimize.sh 4D 325 1T Perf Overlap
```

# Running Training Performance and Network Cost Estimation
Once Network BW distribution is found by the optimizer above, the user then can plug in the found BW setting and run the performance and network cost profiler. As Fig 12-15 of the paper has a plethora of datapoints, we have run the optimizer and pre-populated the setup (`evaluation_input/script_full`). We provide `evaluate.sh` to run the experiments and reproduce each figure.

## Small Experiment
As Fig 12-15 all have a number of datapoints, the full simulation on the Docker container can take days to finish. In order to speed up the AE process, we created a **small** experimental setup. Instead of fully simulating the entire plot, the `small` experiment simulates only the subset of each experiment and reproduces the first subplot of Fig 12-14 (unfortunately, Fig 15 is inherently comparing among all the other results and requires full simulation).

To run the small experiment, first, run the command below to enter the Docker container:
```bash
docker run -v $(pwd)/output:/output -it sc245-artifact  // opens container shell
```

Once ready, please initiate the small experiment:
```bash
evaluate.sh small
top  // to check simulation status
```
This creates multiple background profiling jobs and can take hours, so please leave the container open and running. Once finished, you can exit the container.

When the evaluation is fully done, you can plot each subfigure by running the script below:
```bash
docker run -v $(pwd)/output:/output sc245-artifact plot.sh small <Fig>
```
- Fig (case-sensitive): `fig12`, `fig13`, `fig14`

This will generate the very first subplot of each figure. You can check the result at `output/graph_small/`.

## Full Experiment
Still, if you have enough time to simulate the entire configuration, you can easily run the full simulation in a very analogous manner shown above.
```bash
docker run -v $(pwd)/output:/output -it sc245-artifact  // opens container shell
evaluate.sh full
top  // if you want to check the status
```
This creates lots of (755 in total) background profiling jobs, so please be patient and leave the container shell open. Once fully executed (i.e., no remaining background jobs when you check by `top`), you can exit the container shell and plot the figures:
```bash
docker run -v $(pwd)/output:/output sc245-artifact plot.sh full <Fig>
```
- Fig (case-sensitive): `fig12`, `fig13`, `fig14`, `fig15`

This will reproduce the full plot. You can check the figures at `output/graph_full/`.
