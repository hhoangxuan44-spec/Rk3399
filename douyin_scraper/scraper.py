import os
import time
import requests
import hashlib
import json
import warnings
from PIL import Image
from playwright.sync_api import sync_playwright

# 屏蔽 transformers 和 torch 的告警信息
warnings.filterwarnings("ignore")

def generate_image_description(image_path):
    try:
        from transformers import BlipProcessor, BlipForConditionalGeneration
        import torch
        print(f"正在为 {image_path} 生成描述...")
        # 使用轻量级 BLIP 模型
        processor = BlipProcessor.from_pretrained("Salesforce/blip-image-captioning-base")
        model = BlipForConditionalGeneration.from_pretrained("Salesforce/blip-image-captioning-base")

        raw_image = Image.open(image_path).convert('RGB')

        # unconditional image captioning
        inputs = processor(raw_image, return_tensors="pt")
        out = model.generate(**inputs)
        description = processor.decode(out[0], skip_special_tokens=True)
        return description
    except Exception as e:
        print(f"生成描述失败: {e}")
        return "描述生成失败"

def create_directory(directory_name):
    if not os.path.exists(directory_name):
        os.makedirs(directory_name)

def generate_filename(url):
    md5_hash = hashlib.md5(url.encode('utf-8')).hexdigest()
    ext = ".jpg"
    if ".png" in url.lower(): ext = ".png"
    elif ".webp" in url.lower(): ext = ".webp"
    elif ".jpeg" in url.lower(): ext = ".jpeg"
    return f"{md5_hash[:10]}{ext}"

def download_file(url, folder_path, file_name):
    try:
        # 添加 User-Agent 避免 403
        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        }
        response = requests.get(url, headers=headers, stream=True, timeout=10)
        response.raise_for_status()
        file_path = os.path.join(folder_path, file_name)
        with open(file_path, 'wb') as file:
            for chunk in response.iter_content(chunk_size=8192):
                file.write(chunk)
        return file_path
    except Exception as e:
        print(f"下载失败: {file_name}, 错误: {e}")
        return None

def scrape_category(category, base_folder="gallery", max_items=5):
    folder_path = os.path.join(base_folder, category)
    create_directory(folder_path)
    print(f"\n开始收集分类: {category}")

    results = []
    # 使用搜狗图片搜索作为示例源
    search_url = f"https://pic.sogou.com/pics?query={category}"

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(
            user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            viewport={"width": 1920, "height": 1080}
        )
        page = context.new_page()
        print(f"正在搜索 {category}...")

        try:
            page.goto(search_url, wait_until="domcontentloaded", timeout=30000)
            page.wait_for_timeout(3000)
        except Exception as e:
            print(f"页面加载报错: {e}")

        print("开始提取图片链接...")
        # 搜狗图片的通用图片选择器
        media_elements = page.query_selector_all('ul.figure-list li .figure-image img')
        if not media_elements:
             media_elements = page.query_selector_all('img')

        count = 0
        for el in media_elements:
            if count >= max_items:
                break

            src = el.get_attribute('src')
            if not src:
                src = el.get_attribute('data-src')

            if src and src.startswith('http'):
                filename = generate_filename(src)
                print(f"[{count+1}/{max_items}] 下载图片...")
                local_path = download_file(src, folder_path, filename)

                if local_path:
                    # 提取网页自带的描述信息 (alt)
                    alt_text = el.get_attribute('alt') or "无网页描述"

                    description = ""
                    # 简易判断：如果没有足够清晰的自带描述，则调用 AI 识别
                    if not alt_text or alt_text == "无网页描述" or len(alt_text) < 5:
                        description = generate_image_description(local_path)

                    item = {
                        "id": filename.split('.')[0],
                        "category": category,
                        "source_url": src,
                        "local_path": local_path,
                        "alt_text": alt_text,
                        "generated_description": description
                    }
                    results.append(item)
                    count += 1
                time.sleep(0.5)

        browser.close()
    return results

def main():
    base_folder = "gallery"
    create_directory(base_folder)

    categories = ["国家地理", "风景", "文物", "名画"]
    index_data = []

    for cat in categories:
        items = scrape_category(cat, max_items=3) # 限制数量方便测试
        index_data.extend(items)

    index_file = os.path.join(base_folder, "index.json")
    with open(index_file, 'w', encoding='utf-8') as f:
        json.dump(index_data, f, ensure_ascii=False, indent=4)

    print(f"\n全部收集完成！索引已保存至 {index_file}")

if __name__ == "__main__":
    main()
