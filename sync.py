import os
import sys
import tarfile
from huggingface_hub import HfApi, hf_hub_download

api = HfApi()
repo_id = "yanscy/datalistnew"
token = os.getenv("HF_TOKEN")
FILENAME = "latest_backup.tar.gz"

def restore():
    try:
        if not token:
            print("Skip Restore: HF_TOKEN not set")
            return False
        
        print(f"Downloading {FILENAME} from {repo_id}...")
        path = hf_hub_download(
            repo_id=repo_id,
            filename=FILENAME,
            repo_type="dataset",
            token=token
        )
        
        with tarfile.open(path, "r:gz") as tar:
            tar.extractall(path="/data/")
        
        print(f"Success: Restored from {FILENAME}")
        return True
    except Exception as e:
        print(f"Restore Note: No existing backup found or error: {e}")
        return False

def backup():
    pass  # 暂时不实现

if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "backup":
        backup()
    else:
        restore()