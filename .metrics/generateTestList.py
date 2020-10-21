#!/usr/bin/env python3

import argparse
import json

testRunMockCmd = 'printenv; ./scripts/runTest.py '
testRunMockCmdWaves = 'printenv; ./scripts/runTest.py -waves '
testRunRealCmdInFolder = 'printenv; cd ./tests/instance_capacity; dsim -line-cov -linebuf -noopt test.sv '
testRunRealCmdWavesInFolder = 'printenv; cd ./tests/instance_capacity; dsim -line-cov -linebuf -noopt test.sv '
testRunRealCmd = 'printenv; dsim -line-cov -linebuf -noopt ./tests/instance_capacity/test.sv '
testRunRealCmdWaves = 'printenv; dsim -line-cov -linebuf -noopt ./tests/instance_capacity/test.sv '
copyDSIMFiles = 'cp dsim.log /mux-flow/results/dsim.log; cp dsim.env /mux-flow/results/dsim.env; '
copyLogFiles = 'cp simulation.log /mux-flow/results/simulation.log; '
copyDBFiles = 'cp metrics.db /mux-flow/results/metrics.db; cp metrics_history.db /mux-flow/results/metrics_history.db '
copyWaveFiles = 'cp sim.vcd /mux-flow/results/sim.vcd '
copyResults = copyDSIMFiles + copyLogFiles + copyDBFiles
copyResultsWaves = copyResults + "; " + copyWaveFiles



parser = argparse.ArgumentParser(description = 'Launch a regression using the Metrics Platform')
# options for mock tests
parser.add_argument('--duration', '-d', help='Run time in ms', default='random')
parser.add_argument('-bank', '-i', help='set to true if you want to test pinging iron-bank', action='store_true', default=False)
parser.add_argument('-coverage', '-c', help='set to xml, db unset will not upload coverage files', action='store_true', default=False)
parser.add_argument('--result', '-r', help='preset the result of the test run', default='random', choices=['passed', 'failed', 'incomplete', 'random'])
parser.add_argument('-forceIteration', help='set to true if you want to test a test list with many copies of the test each with the same iterations value', action='store_true', default=False)

# options for real tests
parser.add_argument('-realSV', '-s', help='use a real test.sv file for artifacts and results', action='store_true', default=False)
parser.add_argument('--children', help='Control how many instances each node should have.', default="2")
parser.add_argument('--depth', help='Control how deep the node tree should be', default="5")
parser.add_argument('--rounds', help='Control how many rounds the top instance should go through, 1.0 for full coverage', default="1.0")
parser.add_argument('-logs', help='Control detailed message logging', action='store_true', default=False)
parser.add_argument('--svSeed', help='Effects the random choice of ID assigned to instances', default="2")
parser.add_argument('-runFromTestFolder', help='indicate the simulation will be run from the test file folder', action='store_true', default=False)

# options for either mock or real tests
parser.add_argument('--iter', help='The number of times to run the test', required=False, default=None)
parser.add_argument('--seed', help='The seed to use on the test run', required=False, default="random")
parser.add_argument('--build', '-b', help='name of the build to use, comma seperated list for multiple builds', default="scaled-build")

args = parser.parse_args()
testRunCmdOpts = []

testRunCmd = testRunMockCmd
testRunCmdWaves = testRunMockCmdWaves
if args.realSV:
    if args.runFromTestFolder:
        testRunCmd = testRunRealCmdInFolder
        testRunCmdWaves = testRunRealCmdWavesInFolder + "+acc+b -waves sim.vcd "
    else:
        testRunCmd = testRunRealCmd
        testRunCmdWaves = testRunRealCmdWaves + "+acc+b -waves sim.vcd "
    testRunCmdOpts.append("+define+N_OF_CHILDREN=" + args.children)
    testRunCmdOpts.append("+define+HIER_LEVELS=" + args.depth)
    testRunCmdOpts.append("+define+DURATION_IN_ROUNDS=" + args.rounds)
    if args.logs:
        testRunCmdOpts.append("+define+MSG_ON")
    testRunCmdOpts.append("-sv_seed " + args.svSeed)
else:
    testRunCmd += "--duration " + args.duration + " "
    testRunCmdWaves += "--duration " + args.duration + " -waves "
    if args.bank:
        testRunCmdOpts.append('-bank')
    if args.coverage:
        testRunCmdOpts.append('-c')
    testRunCmdOpts.append('--result ' + args.result)


tests = []
def buildTestInfo():
    if args.iter is "0":
        tests.append({})
        return tests
    builds = str(args.build).split(',')
    for b in builds:    
        test = {
            "name": 'qa_scaling_project_test',
            "build": b,
            "cmd": testRunCmd + ' '.join(testRunCmdOpts) + '; ' + copyResults,
            "wavesCmd": testRunCmdWaves + ' '.join(testRunCmdOpts) + '; ' + copyResultsWaves,
            "wavesFile": "sim.vcd"
        }
        if str(args.seed) != "random":
            test["seed"] = int(args.seed)
        if args.coverage:
            test["metricsFile"] = "metrics.db"
        if args.iter is not None:
            if args.forceIteration:
                for i in range(int(args.iter)-1):
                    test["iterations"] = 1
                    tests.append(test)
            else:
                test["iterations"] = int(args.iter)
        tests.append(test)

buildTestInfo()
testFile = open('./testList.json', 'w+')
testFile.write(json.dumps(tests))
testFile.close()
