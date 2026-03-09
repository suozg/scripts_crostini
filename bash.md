
# BASH
---

## ПОШУК І ІНФОРМАЦІЯ

```bash
find /home -name 'file.txt'                 # знайти файл за іменем
find ./ -size +100M -mtime 3 -user alex     # знайти файли понад 100М, змінені за останні 3 дні, належні користувачу alex
grep -r 'error' /var/log                    # пошук тексту у файлах
du -h file.txt                              # показати розмір файлу
file image.png                              # тип файлу
history                                     # перегляд історії команд
history 10                                  # покаже останні 10 команд
history -c                                  # очистить історію
history | grep "docker"                     # пошук в історії
Ctrl+r                                      # пошук в історії (інтерактивно)

!!                                          # повторити останню команду
!42                                         # повторити команду №42 з історії
!git                                        # повторити команду, що починається з git
!?config?                                   # повторити команду, що містить "config"
```

## ПЕРЕНАПРАВЛЕННЯ

```bash
ls > list.txt                       # вивід у файл (перезапис)
echo 'рядок' >> list.txt            # додати у файл
wc -l < file.txt                    # зчитати з файлу
cat file.txt | grep error           # передати через пайп
```

## РОБОТА З АРХІВАМИ

```bash
tar -cvf archive.tar dir/           # створити tar-архів
tar -xvf archive.tar                # розпакувати tar
tar -czvf archive.tar.gz dir/       # стиснути gzip
tar -xzvf archive.tar.gz            # розпакувати gzip
zip -r archive.zip dir/             # створити zip
unzip archive.zip                   # розпакувати zip
```

## ЦИКЛИ

```bash
for f in *.txt; do echo $f; done                    # простий цикл for
for i in {1..5}; do echo $i; done                   # цикл з діапазоном
while read line; do echo $line; done < file.txt     # цикл while
until [ -f done.txt ]; do sleep 1; done             # цикл until
```

## ПОСИЛАННЯ (LINKS)

```bash
ln file.txt hardlink.txt            # створити жорстке посилання
ln -s /path/original.txt link.txt   # створити символічне посилання
ln -s /home/user/docs/ shortcut     # створити посилання на каталог
ls -l link.txt                      # показати, на що вказує посилання
rm link.txt                         # видалити символічне посилання
ln -sf new_target link.txt          # оновити посилання (примусово)
```

## ДОДАТКОВО (СКРИПТИ)

```bash
search_docs.sh <фраза> <шлях>       # пошук по змісту тексту (doc, txt. odt)
pix2pdf.sh [-s /шлях/до/штампа.pdf] # конвертація зображень у PDF
```

