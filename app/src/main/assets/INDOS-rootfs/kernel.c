void main() {
    char *video_memory = (char*) 0xb8000;
    *video_memory = 'I'; // Menampilkan huruf I (INDOS)
}
