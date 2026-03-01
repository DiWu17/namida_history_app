import zipfile
import os
from typing import Optional

class Extractor:
    def __init__(self, backup_zip_path: str, extract_top_path: str):
        self.backup_zip_path = backup_zip_path
        self.extract_top_path = extract_top_path
        self.history_zip_name = "TEMPDIR_History.zip"

    def extract_history_folder(self) -> Optional[str]:
        if not os.path.exists(self.backup_zip_path):
            return None

        os.makedirs(self.extract_top_path, exist_ok=True)
        temp_internal_zip = os.path.join(self.extract_top_path, self.history_zip_name)
        
        try:
            with zipfile.ZipFile(self.backup_zip_path, 'r') as main_zip:
                if self.history_zip_name in main_zip.namelist():
                    main_zip.extract(self.history_zip_name, self.extract_top_path)
                else:
                    return None

            final_history_dir = os.path.join(self.extract_top_path, "TEMPDIR_History")
            os.makedirs(final_history_dir, exist_ok=True)

            with zipfile.ZipFile(temp_internal_zip, 'r') as history_zip:
                history_zip.extractall(final_history_dir)

            if os.path.exists(temp_internal_zip):
                os.remove(temp_internal_zip)

            return final_history_dir

        except Exception as e:
            return None
