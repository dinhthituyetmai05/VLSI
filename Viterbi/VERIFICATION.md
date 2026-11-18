# Kết quả kiểm tra ngày 28/10/2026

Sau khi tách `viterbi_control.v`, đã chạy lại toàn bộ regression dưới đây
và kiểm tra compile Verilog-2001. Top `viterbi_decoder.v` chỉ nối dây và
instantiate bốn module con. Cổng ngoài, quy tắc giải mã và độ trễ 17 chu kỳ
được giữ nguyên; không thêm thanh ghi pipeline.

RTL đã được biên dịch và mô phỏng bằng Icarus Verilog. Kết quả thực tế:

```text
PASS: 65797 frames in BOTH bit-order modes; all 65536 received words
PASS: 256 file vectors
```

- 65.536 từ nhận 16 bit: so với oracle tìm kiếm toàn bộ 256 codeword,
  kiểm tra kết quả giải mã cụ thể, bao gồm quy tắc xử lý hòa.
- 256 khung sạch: khôi phục chính xác cả 256 byte thông tin.
- 5 khung phục hồi sau reset ở các giai đoạn khác nhau.
- Mỗi khung được chạy trên hai DUT với MSB_FIRST=0 và MSB_FIRST=1.
- Kiểm tra độ trễ 17 chu kỳ, busy, start khi busy, thay đổi đầu vào sau chốt,
  xung done và giữ kết quả.
- 256 cặp file nhị phân mẫu: testbench đọc và so sánh tự động, pass 100%.
- RTL biên dịch riêng với `-g2001 -Wall -s viterbi_decoder -t null -c src/files.f`:
  thành công, không có cảnh báo.

Các log mô phỏng và oracle được tạo trong build/ khi chạy scripts/run_tests.py.

Chưa có input.txt/output.txt chính thức của giảng viên nên chưa kiểm tra
pass trên bộ dữ liệu đó. Những từ nhận có nhiều lỗi hoặc hòa có thể không
khôi phục bản tin gốc; phép kiểm tra exhaustive xác nhận đúng nghiệm
maximum-likelihood theo khoảng cách Hamming và quy tắc hòa đã công bố.

Chưa có tổng hợp với thư viện công nghệ, STA sau layout hoặc phân tích công
suất. Clock 5 ns trong testbench/SDC là mục tiêu 200 MHz; chưa phải bằng
chứng đạt tần số, diện tích hoặc công suất theo đề.
