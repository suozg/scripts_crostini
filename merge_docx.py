#!/usr/bin/env python3
import os
import subprocess
import sys

def merge_all_formats(folder_path, output_filename="merged.odt"):
    # Перелік розширень, які ми шукаємо для об'єднання
    valid_extensions = (".docx", ".odt", ".doc", ".rtf")
    
    # Збираємо всі файли потрібних форматів, ігноруючи вихідний файл та тимчасові файли Word (~$)
    input_files = [
        f for f in sorted(os.listdir(folder_path))
        if f.lower().endswith(valid_extensions) and f != output_filename and not f.startswith("~$")
    ]

    if not input_files:
        print("Файлів для об'єднання не знайдено (.docx, .odt, .doc, .rtf).")
        return

    print(f"Знайдено файлів для об'єднання: {len(input_files)}")

    # Перевіряємо наявність pandoc
    if not subprocess.run(["which", "pandoc"], stdout=subprocess.DEVNULL).returncode == 0:
        print("❌ Помилка: Pandoc не встановлено в системі!")
        print("Виконайте: sudo apt install pandoc")
        return

    # Тимчасова папка для конвертації
    tmp_dir = "/tmp/document_merge"
    os.makedirs(tmp_dir, exist_ok=True)
    
    html_parts = []

    # Крок 1: Конвертуємо кожен знайдений файл (будь-якого формату) в HTML через LibreOffice
    for index, filename in enumerate(input_files):
        file_path = os.path.abspath(os.path.join(folder_path, filename))
        print(f"Обробка ({filename.split('.')[-1].upper()}): {filename}...")
        
        # LibreOffice автоматично розпізнає формат (odt, doc, rtf, docx) і переведе в html
        subprocess.run([
            "soffice", "--headless", "--convert-to", "html", 
            "--outdir", tmp_dir, file_path
        ], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        
        # Визначаємо ім'я згенерованого HTML-файлу
        base_name = filename.rsplit('.', 1)[0]
        html_name = base_name + ".html"
        html_path = os.path.join(tmp_dir, html_name)
        
        if os.path.exists(html_path):
            with open(html_path, "r", encoding="utf-8", errors="ignore") as f:
                content = f.read()
                # Витягаємо лише вміст body
                if "<body>" in content and "</body>" in content:
                    body_content = content.split("<body>")[1].split("</body>")[0]
                    html_parts.append(body_content)
                else:
                    html_parts.append(content)
                    
            # Додаємо розділювач сторінок між файлами
            if index < len(input_files) - 1:
                html_parts.append('<div style="page-break-after:always"></div>')
        else:
            print(f"⚠️ Попередження: Не вдалося обробити файл {filename}")

    if not html_parts:
        print("❌ Помилка: Не вдалося підготувати проміжні дані.")
        return

    # Крок 2: Зшиваємо всі шматки HTML в один файл
    merged_html_path = os.path.join(tmp_dir, "combined.html")
    with open(merged_html_path, "w", encoding="utf-8") as f:
        f.write("<html><head><meta charset='utf-8'></head><body>")
        f.write("\n".join(html_parts))
        f.write("</body></html>")

    # Крок 3: Збираємо фінальний файл через Pandoc (формат визначається розширенням у output_filename)
    output_path = os.path.abspath(os.path.join(folder_path, output_filename))
    fmt_upper = output_filename.split('.')[-1].upper()
    print(f"Збірка фінального файлу у форматі {fmt_upper} через Pandoc...")
    
    final_result = subprocess.run([
        "pandoc", merged_html_path, "-o", output_path
    ], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

    if os.path.exists(output_path) and os.path.getsize(output_path) > 0:
        print(f"\n✅ Успішно! Все склеєно в один файл: {output_filename}")
    else:
        print("\n❌ Помилка під час збірки файлу через Pandoc.")
        if final_result.stderr:
            print(final_result.stderr)

    # Очищення тимчасової папки
    try:
        for f in os.listdir(tmp_dir):
            os.remove(os.path.join(tmp_dir, f))
        os.rmdir(tmp_dir)
    except Exception:
        pass

if __name__ == "__main__":
    # Читаємо ім'я файлу, яке передав lf. За замовчуванням робимо merged.odt
    output_file = sys.argv[1] if len(sys.argv) > 1 else "merged.odt"
    merge_all_formats(".", output_file)
