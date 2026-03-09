import os
from docx import Document

def merge_docx_files(folder_path, output_filename="merged.docx"):
    merged_document = Document()

    first_file = True
    for filename in sorted(os.listdir(folder_path)):
        if filename.endswith(".docx"):
            file_path = os.path.join(folder_path, filename)
            doc = Document(file_path)
            if not first_file:
                merged_document.add_page_break()
            else:
                first_file = False
            for element in doc.element.body:
                merged_document.element.body.append(element)

    merged_document.save(os.path.join(folder_path, output_filename))
    print(f"Объединённый файл сохранён как: {output_filename}")

# Пример использования
merge_docx_files(".")  # Текущая директория
