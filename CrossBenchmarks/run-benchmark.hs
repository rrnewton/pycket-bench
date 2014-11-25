{-# LANGUAGE NamedFieldPuns #-}

-- | HSBencher script to run all the benchmarks.

module Main where

import HSBencher
import HSBencher.Backend.Fusion    (defaultFusionPlugin)
-- import HSBencher.Backend.Codespeed (defaultCodespeedPlugin, CodespeedConfig(..))
import HSBencher.Backend.Dribble   (defaultDribblePlugin)
import HSBencher.Methods.Builtin   (makeMethod)

import qualified Control.Monad.Trans as Trans

import Data.Default (Default(def))
import Data.Monoid (mappend)
import qualified Data.Map as M
import System.Environment (getEnvironment)
import System.Directory   (setCurrentDirectory, getDirectoryContents, getCurrentDirectory)
import System.IO.Unsafe   (unsafePerformIO)
import System.Process     
import GHC.Conc           (getNumProcessors)

--------------------------------------------------------------------------------

benches :: [Benchmark DefaultParamMeaning]
benches = 
  [ (mkBenchmark ("../bin/run-"++which) [mode, prog]
      (And [ allBenchParams, Set (Variant (which++mode)) (RuntimeArg "") ]))
     { progname = Just ("CrossBench-"++prog) }
  | prog <- words "ack array1 browse cat conform cpstak ctak dderiv deriv destruc diviter divrec dynamic earley fft fib fibc fibfp gcbench gcold graphs lattice matrix maze mazefun mbrot nqueens nucleic paraffins parsing perm9 peval pi pnpoly primes puzzle ray scheme simplex string sum sumfp sumloop tail tak takl trav1 trav2 triangl wc"
-- slatex
--  , mode <- ["-nothing", "-fixflo", "-unsafe"]
  , mode <- ["-nothing"]
  , which <- ["racket", "pycket"] ]

--    confidence_level: 0.95
--     number_of_data_points: 10
--    max_time: 60   # time in seconds

--         #variable_values: [nothing, fixflo, unsafe]


--------------------------------------------------------------------------------
-- Param settings and sizes:
--------------------------------------------------------------------------------

allBenchParams :: BenchSpace DefaultParamMeaning
allBenchParams = And []

--------------------------------------------------------------------------------

main :: IO ()
main = do
  putStrLn "Begin Pycket benchmarks..."
  defaultMainModifyConfig $ \ conf ->
    addPlugin defaultFusionPlugin fsconf $ 
    addPlugin defaultDribblePlugin def $ 
--    addPlugin defaultCodespeedPlugin csconf $ 
    conf{ benchlist  = benches
        , runTimeOut = Just 30
        , buildMethods = [ shellMethod ]
        , harvesters = customTagHarvesterDouble "RESULT-cpu"   `mappend`
                       customTagHarvesterDouble "RESULT-gc"    `mappend`
                       customTagHarvesterDouble "RESULT-total" `mappend`
                       harvesters conf
        }
 where
  -- Some default settings for benchmarking:
  -- csconf = def { codespeedURL = "http://codespeed.crest.iu.edu"
  --              , projName     = "LVishParInfer" }

  -- By default we can bake settings in here rather than passing them
  -- on the command line:
  fsconf = def 
-- CID=820162629229-kp29aklebt6ucos5a71u8tu3hu8unres.apps.googleusercontent.com
-- SEC=pSsMxVAJCFKyWsazuxZVRZwX

-- | Teach HSBencher how to run a shell script or already-built binary.
shellMethod :: BuildMethod
shellMethod = BuildMethod
  { methodName = "shell-script-or-binary"
  , canBuild = AnyFile
  , concurrentBuild = False
  , setThreads      = Nothing
  , clean = \ pathMap _ target -> return ()
  , compile = \ pathMap bldid flags target -> do
--       _ <- Trans.lift $ system "raco pkg install gcstats"
       let runit args envVars =
             CommandDescr
             { command = ShellCommand
                         (target++" "++ unwords args)
             , timeout = Just 30                         
             , workingDir = Nothing
             , envVars
             , tolerateError = False
             }
       return (RunInPlace runit)
  }
