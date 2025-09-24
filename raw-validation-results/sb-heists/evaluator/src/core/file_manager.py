import os
import shutil

from config import DEFAULT_BACKUP_SUFFIX
from exceptions import PatchEvaluatorError
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class FileManager:
    def __init__(self, base_directory: str):
        print(f"Base directory: {base_directory}")
        self.base_directory = base_directory
        self.backup_directory = os.path.join(base_directory, "backups")
        os.makedirs(self.backup_directory, exist_ok=True)

    def _normalize_incoming_path(self, path: str) -> str:
        """
        Normalize paths provided by callers so that repeated repo prefixes like
        'smartbugs-curated/0.4.x/smartbugs-curated/0.4.x/...'
        are collapsed into a single prefix and leading '../' or './' are removed.
        This makes the evaluator defensive against callers that accidentally pass
        a repo-root-prefixed path instead of a path relative to the evaluator base.
        """
        if not path:
            return path

        # Collapse repeated occurrences of the repo prefix
        prefix = "smartbugs-curated/0.4.x"
        # Replace repeated sequences of prefix/prefix/... with single prefix
        # Do several iterations until stable (covers many repeats)
        prev = None
        p = path
        while p != prev:
            prev = p
            p = p.replace(prefix + '/' + prefix + '/', prefix + '/')
            p = p.replace(prefix + '/' + prefix, prefix)

        # Remove any leading '../' or './' fragments that would otherwise
        # cause double-relative joins.
        while p.startswith('../'):
            p = p[3:]
        while p.startswith('./'):
            p = p[2:]

        # If path still starts with the repo prefix, strip a single leading
        # occurrence so we use a path relative to evaluator base.
        if p.startswith(prefix + '/'):
            p = p[len(prefix) + 1:]
        elif p == prefix:
            p = ''

        # Normalize path separators
        p = os.path.normpath(p)
        return p

    def read_file(self, path: str, absolute: bool = False) -> str:
        full_path = os.path.join(self.base_directory, path) if not absolute else path
        try:
            with open(full_path, 'r') as f:
                return f.read()
        except IOError as e:
            raise PatchEvaluatorError(f"Failed to read file {path}: {str(e)}")

    def write_file(self, path: str, content: str, absolute: bool = False):
        full_path = os.path.join(self.base_directory, path) if not absolute else path
        try:
            os.makedirs(os.path.dirname(full_path), exist_ok=True)
            with open(full_path, 'w') as f:
                f.write(content)
        except IOError as e:
            raise PatchEvaluatorError(f"Failed to write file {path}: {str(e)}")

    def backup(self, path: str):
        logger.info(f"+++++++++++++++++++++++ Base directory is: {self.base_directory}")
        logger.info(f"+++++++++++++++++++++++ Path: {path}")
        # Defensive normalization of incoming path
        normalized = self._normalize_incoming_path(path)
        logger.info(f"Normalized path for backup: {normalized}")
        # The source file lives under the evaluator base directory (usually
        # ../smartbugs-curated/0.4.x). Use that base directory to locate the
        # contract file, not a plain '..' join which produced incorrect paths.
        source = os.path.join(self.base_directory, normalized) if normalized else self.base_directory
        logger.info(f"Source path: {source}")
        logger.info(f"Backing up file {source} to {self.backup_directory}")

        backup = f"{os.path.join(self.backup_directory, normalized)}{DEFAULT_BACKUP_SUFFIX}"
        logger.info(f"Backup path: {backup}")

        os.makedirs(os.path.dirname(backup), exist_ok=True)
        try:
            logger.info('.... <> .....')
            shutil.copy2(source, backup)
        except IOError as e:
            raise PatchEvaluatorError(f"Failed to backup file {path}: {str(e)}")

    def restore(self, path: str):
        normalized = self._normalize_incoming_path(path)
        logger.info(f"Normalized path for restore: {normalized}")

        source = os.path.join(self.base_directory, normalized) if normalized else os.path.join(self.base_directory)
        backup = f"{os.path.join(self.backup_directory, normalized)}{DEFAULT_BACKUP_SUFFIX}"
        try:
            if os.path.exists(backup):
                shutil.move(backup, source)
        except IOError as e:
            raise PatchEvaluatorError(f"Failed to restore file {path}: {str(e)}")
    
    def remove_backup(self):
        if os.path.exists(self.backup_directory):
            shutil.rmtree(self.backup_directory)
