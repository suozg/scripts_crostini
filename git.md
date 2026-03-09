# 🐧 GITHUB 
---

## НАЛАШТУВАННЯ SSH1. 

1. Генерація ключа:
```bash
ssh-keygen -t ed25519 -C "your@email.com"  # Enter до кінця
cat ~/.ssh/id_ed25519.pub                  # Скопіювати результат
```
2. Додавання на GitHub:
- GitHub.com -> 
- Settings -> 
- SSH and GPG keys -> 
- New SSH key -> 
- Вставити ключ.

4. Конфігурація Git:
```bash
git config --global user.name "Ваше Ім'я"
git config --global user.email "your@email.com"
```
4. Змінити Remote на SSH:
```bash
git remote set-url origin git@github.com:користувач/репозиторій.git
```

## ОСНОВНІ КОМАНДИ GIT

| Команда              | Опис                             |
|----------------------|----------------------------------|
| git init             | Створити репозиторій локально    |
| git clone [URL]      | Завантажити репозиторій з GitHub |
| git status           | Перевірити зміни                 |
| git add .            | Підготувати файли                |
| git commit -m ".."   | Зберегти зміни локально          |
| git push origin main | Відправити на GitHub             |
| git pull origin main | Оновити локальну версію          |

SSH-агент (якщо постійно просить пароль):

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

## ГІЛКИ ТА КОНФЛІКТИ

```bash
git checkout -b [name]    # Нова гілка
git merge [name]          # Злити гілку в поточну
```

Конфлікт: Відкрити файл, стерти <<<< ==== >>>>, залишити потрібний код, потім 
```bash
git add та git commit.
```

