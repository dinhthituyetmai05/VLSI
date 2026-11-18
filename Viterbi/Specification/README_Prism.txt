BAO CAO SPECIFICATION VITERBI - NGUON LATEX

1. Noi dung
- main.tex: nguon bao cao day du, gom ca phan controller K1-K9.
- Images/: cac hinh goc, Controller Overview, controller datapath va logo.
- Viterbi_Specification.pdf: ban PDF da bien dich va kiem tra bo cuc.

2. Su dung tren Prism
Tai main.tex va thu muc Images len cung mot project; giu nguyen ten thu muc
va ten tep. Chon main.tex lam tep chinh va XeLaTeX lam compiler neu co lua
chon. Font TeX Gyre Termes co trong cac bo TeX thong dung. Cac duong dan
hinh chi dung ky tu ASCII de tranh loi ten thu muc co dau.

main.tex la mot tep nguon doc lap, khong dung input/include cac chuong khac.
Nguon co nhanh tuong thich pdfLaTeX, nhung ban PDF giao kem duoc kiem tra
bang Tectonic 0.17.0 (engine XeTeX).

3. Pham vi cap nhat
- Giu bo cuc bao cao BTL theo mau VLSI_report.pdf.
- Bo sung hai hinh controller, ban datapath day du va cac vung phong to.
- Giai thich giao tiep, thanh ghi, FSM, dieu kien cap nhat va reset.
- Lam ro do tre 17 chu ky, khoang nhan khung 18 chu ky va thu tu MSB-first.
- Them vi du metric va traceback day du cho 8'h19 / 16'h35FB.
- Trich ket qua mo phong da luu; khong coi muc tieu PPA la ket qua do.

Khong sua cac tep RTL hoac testbench.
Ban nguon tren Prism chua duoc cap nhat truc tiep trong phien lam viec nay.
