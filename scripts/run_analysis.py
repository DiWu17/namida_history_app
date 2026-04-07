import sys
import json
import os
from extractor import Extractor
from parser import Parser

def main():
    if len(sys.argv) < 2:
        print(json.dumps({"error": "缺少备用文件路径参数"}))
        return

    zip_arg = sys.argv[1]
    music_dir = sys.argv[2] if len(sys.argv) > 2 else None
    
    import tempfile
    import shutil
    
    # Support multiple ZIP paths separated by |
    zip_paths = [p.strip() for p in zip_arg.split('|') if p.strip()]
    
    # Use a fixed tmp dir inside the user's temp
    extract_to = os.path.join(tempfile.gettempdir(), "namida_history_temp")
    merged_dir = os.path.join(extract_to, "TEMPDIR_History_merged")
    
    # Clean previous run
    if os.path.exists(extract_to):
        shutil.rmtree(extract_to, ignore_errors=True)

    os.makedirs(merged_dir, exist_ok=True)

    success_count = 0
    for i, zip_path in enumerate(zip_paths):
        sub_extract = os.path.join(extract_to, f"zip_{i}")
        extractor = Extractor(zip_path, sub_extract)
        result_path = extractor.extract_history_folder()
        if result_path and os.path.exists(result_path):
            # Merge JSON files by filename (ignoring source path)
            for fname in os.listdir(result_path):
                if not fname.endswith('.json'):
                    continue
                src_file = os.path.join(result_path, fname)
                dst_file = os.path.join(merged_dir, fname)
                try:
                    with open(src_file, 'r', encoding='utf-8-sig') as f:
                        new_records = json.load(f)
                    if not isinstance(new_records, list):
                        continue
                    if os.path.exists(dst_file):
                        with open(dst_file, 'r', encoding='utf-8-sig') as f:
                            existing_records = json.load(f)
                        existing_records.extend(new_records)
                        with open(dst_file, 'w', encoding='utf-8') as f:
                            json.dump(existing_records, f, ensure_ascii=False)
                    else:
                        with open(dst_file, 'w', encoding='utf-8') as f:
                            json.dump(new_records, f, ensure_ascii=False)
                except Exception:
                    pass
            success_count += 1
            # Cleanup individual extraction
            shutil.rmtree(result_path, ignore_errors=True)

    if success_count > 0:
        parser = Parser(merged_dir, music_dir)
        df = parser.load_all_history()
        summaries = parser.get_all_summaries()
        
        shutil.rmtree(extract_to, ignore_errors=True)

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
