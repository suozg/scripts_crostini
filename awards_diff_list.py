import argparse
import re
import pandas as pd


def clean_pib(text: str) -> str:
    """Очищає та нормалізує ПІБ для порівняння."""
    if not isinstance(text, str):
        return ""

    text = text.strip().lower()

    # Усуваємо проблему з різними мовними розкладками (англ 'i', 'e', 'o' -> укр 'і', 'е', 'о')
    charmap = {
        "a": "а",
        "b": "в",
        "c": "с",
        "e": "е",
        "i": "і",
        "k": "к",
        "m": "м",
        "o": "о",
        "p": "р",
        "x": "х",
        "y": "у",
        "H": "н",
        "I": "і",
    }
    for eng, ukr in charmap.items():
        text = text.replace(eng, ukr)

    # Прибираємо цифри та спецсимволи
    text = re.sub(r"\d+", "", text)
    text = re.sub(r"[^\w\s\u0400-\u04FF\u0500-\u052F']", " ", text)
    return " ".join(text.split())


def find_pib_column(df: pd.DataFrame) -> str:
    """Автоматично шукає назву або індекс стовпчика, в якому містяться ПІБ (а не звання чи посада)."""
    # 1. Спочатку шукаємо за назвою заголовка
    for col in df.columns:
        if "піб" in str(col).lower() or "пiб" in str(col).lower():
            return col

    # 2. Якщо назви немає — аналізуємо вміст стовпчиків
    # ПІБ зазвичай складається з 2-4 слів (Прізвище Ім'я По батькові)
    best_col = df.columns[0]
    max_pib_count = -1

    for col in df.columns:
        pib_like_count = 0
        sample_vals = df[col].dropna().astype(str).head(50)
        for val in sample_vals:
            words = val.strip().split()
            # Посада чи звання — це зазвичай 1 слово ("майор") або не схоже на ПІБ.
            # ПІБ має 2-4 слова і не містить цифр
            if 2 <= len(words) <= 4 and not any(c.isdigit() for c in val):
                pib_like_count += 1

        if pib_like_count > max_pib_count:
            max_pib_count = pib_like_count
            best_col = col

    return best_col


def read_csv_smart(file_path: str) -> pd.DataFrame:
    """Універсальне читання CSV."""
    for skiprows in [0, 1, 2]:
        try:
            try:
                df = pd.read_csv(
                    file_path,
                    skiprows=skiprows,
                    encoding="utf-8",
                    header=None if skiprows > 0 else "infer",
                )
            except UnicodeDecodeError:
                df = pd.read_csv(
                    file_path,
                    skiprows=skiprows,
                    encoding="cp1251",
                    header=None if skiprows > 0 else "infer",
                )

            if not df.empty:
                return df
        except Exception:
            continue

    # Резервний варіант
    try:
        return pd.read_csv(file_path, encoding="utf-8", header=None)
    except UnicodeDecodeError:
        return pd.read_csv(file_path, encoding="cp1251", header=None)


def main():
    parser = argparse.ArgumentParser(
        description="Точне порівняння ПІБ у двох CSV файлах."
    )
    parser.add_argument(
        "file_all", help="1-й CSV файл (список усіх людей із даними)"
    )
    parser.add_argument(
        "file_rewarded", help="2-й CSV файл (список нагороджених)"
    )
    parser.add_argument(
        "-o",
        "--output",
        default="не_отримали_нагороду.csv",
        help="Файл для збереження",
    )

    args = parser.parse_args()

    # Зчитуємо файли
    df_all = read_csv_smart(args.file_all)
    df_rewarded = read_csv_smart(args.file_rewarded)

    # Автоматично визначаємо, в яких стовпчиках лежать ПІБ
    col_pib_all = find_pib_column(df_all)
    col_pib_rewarded = find_pib_column(df_rewarded)

    print(
        f"У 1-му файлі ПІБ знайдено в стовпчику: '{col_pib_all}' (всього рядків: {len(df_all)})"
    )
    print(
        f"У 2-му файлі ПІБ знайдено в стовпчику: '{col_pib_rewarded}' (всього рядків: {len(df_rewarded)})"
    )

    # Нормалізуємо ПІБ з 2-го файлу (множина нагороджених)
    rewarded_set = set(
        df_rewarded[col_pib_rewarded]
        .dropna()
        .astype(str)
        .apply(clean_pib)
        .values
    )
    # Видаляємо службові слова
    rewarded_set.discard("піб")
    rewarded_set.discard("")

    # Додаємо тимчасову колонку для порівняння в 1-й файл
    df_all["_clean_pib_key"] = df_all[col_pib_all].astype(str).apply(clean_pib)

    # Відбираємо людей, чий ПІБ ВІДСУТНІЙ у 2-му файлі
    df_not_rewarded = df_all[~df_all["_clean_pib_key"].isin(rewarded_set)].copy()

    # Прибираємо тимчасову колонку
    df_not_rewarded.drop(columns=["_clean_pib_key"], inplace=True)

    # Зберігаємо результат (з усіма початковими колонками: звання, ПІБ, посада тощо)
    df_not_rewarded.to_csv(args.output, index=False, encoding="utf-8-sig")

    print("\n--- РЕЗУЛЬТАТ ---")
    print(f"Знайдено людей без нагород: {len(df_not_rewarded)}")
    print(f"Результат збережено у: {args.output}")


if __name__ == "__main__":
    main()
