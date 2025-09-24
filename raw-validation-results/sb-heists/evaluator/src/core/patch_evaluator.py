from models.patch import Patch
from models.test_result import TestResult
from core.file_manager import FileManager
from core.strategy_factory import PatchStrategyFactory
from testing.hardhat_runner import HardhatTestRunner
import logging

class PatchEvaluator:
    def __init__(self, base_directory: str):
        self.file_manager = FileManager(base_directory)
        self.patch_factory = PatchStrategyFactory()
        self.test_runner = HardhatTestRunner(base_directory)
        self.logger = logging.getLogger(__name__)

    def evaluate_patch(self, patch: Patch) -> TestResult:
        print(f'>>>> Evaluating patch: {patch.path} for contract: {patch.contract_file}')
        print(f'Patch is ::: {patch}')
        strategy = self.patch_factory.create_strategy(patch)
        print(f"Evaluating patch: {patch.path} for contract: {patch.contract_file}")

        try:
            contract_path = strategy.contract_path(patch)
            print(f"======> Backing up contract at: {contract_path}")
            
            self.file_manager.backup(contract_path)

            print("Applying patch...")
            strategy.apply(patch, self.file_manager)

            print("Running tests...")
            test_result = self.test_runner.run_tests(patch, strategy)
            print(f"Parsed test result is: {test_result} \n")

            #print("Restoring original contract")
            print("%%%%%%%%%%%%%%%%%%%%%%%%%%%  %%%% %%%%%%%%%%%%%%%%%%%%%%%%%%  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% <")
            self.file_manager.restore(contract_path)
            print("+++++++++++++++++++++++++++++++++++++++++++++++++++++++++")

            #print(f"Evaluation complete. Passed tests: {test_result.passed_tests}/{test_result.total_tests}")
            return test_result

        except Exception as e:
            self.logger.error(f"Error during patch evaluation: {str(e)}")
            try:
                self.file_manager.restore(strategy.contract_path(patch))
            except Exception as re:
                self.logger.error(f"Error while attempting restore: {str(re)}")
            # Return a TestResult indicating failure with the exception message
            return TestResult(
                contract=patch.contract_file,
                patch_path=patch.path,
                total_tests=0,
                passed_tests=0,
                failed_tests=0,
                sanity_success=0,
                sanity_failures=1,
                failed_sanity_results=[str(e)],
                failed_results=[str(e)],
                passed_results=[]
            )
        finally:
            self.file_manager.remove_backup()