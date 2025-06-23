# TuxonOS

Um sistema operacional com base Ubuntu desenvolvido para a empresa Tuxon Soluções Web.

Para compilar o OS basta utilizar o comando:
```bash
bash build-nogui.sh
```

Apos compilar o container e necessario extrair o bootloader, para isso utilize o comando
```bash
/bzImage -initrd=/init.cpio
```