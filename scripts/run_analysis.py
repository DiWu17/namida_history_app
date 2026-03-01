import sys
import json
import os
from extractor import Extractor
from parser import Parser

def main():
    if len(sys.argv) < 2:
        print(json.dumps({"error": "缺少备用文件路径参数"}))
        return

    backup_zip = sys.argv[1]
    music_dir = sys.argv[2] if len(sys.argv) > 2 else None
    
    import tempfile
    
    # Use a fixed tmp dir inside the user's temp
    extract_to = os.path.join(tempfile.gettempdir(), "namida_history_temp")

    # Extract
    extractor = Extractor(backup_zip, extract_to)
    result_path = extractor.extract_history_folder()
    
    if result_path and os.path.exists(result_path):
        parser = Parser(result_path, music_dir)
        df = parser.load_all_history()
        summaries = parser.get_all_summaries()
        
        # Cleanup temp directory optionally if we don't need it later
        import shutil
        shutil.rmtree(result_path, ignore_errors=True)

        print(json.dumps({
            "success": True,
            "summaries": summaries
        }))
    else:
        print(json.dumps({
            "success": False,
            "error": "提取历史文件夹失败，请检查ZIP格式或路径"
        }))

if __name__ == "__main__":
    main()
