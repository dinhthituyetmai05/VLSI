# Kết quả kiểm tra ngày 24/11/2026

Giao tiếp đã sửa theo hai hình yêu cầu: top `viterbi_top`, chỉ có sáu cổng
`clk`, `rstn`, `viterbi_enable`, `input_data[15:0]`, `output_data[7:0]`,
`output_done`. Reset bất đồng bộ tích cực mức thấp, dùng
`always @(posedge clk or negedge rstn)` và `if (!rstn)` trong controller.

`busy` trước đây là phép so sánh `control_state != IDLE`, chỉ báo trạng thái
ra ngoài. Đã bỏ cổng này khỏi top và controller. Việc nhận khung vẫn do
nhánh IDLE của FSM quyết định; enable trong khi xử lý bị bỏ qua. Bên gửi
có thể đặt khung mới sau khi thấy output_done=1, để nhận tại cạnh lên kế tiếp.
Đã bỏ tham số chọn chiều đọc khỏi top và controller. Chiều đọc cố định từ
input_data[15:14] đến input_data[1:0]; bit thông tin đầu tiên nằm ở
output_data[7]. Thuật toán và độ trễ 17 chu kỳ được giữ nguyên.

Đã chạy thực tế bằng Icarus Verilog:

```text
PASS: 65799 frames in fixed MSB-first order; all 65536 received words
PASS: 256 file vectors
```

- 65.536 từ nhận 16 bit so với oracle độc lập tìm kiếm đủ 256 codeword.
- 256 bản tin sạch và ví dụ mã hóa 8'h19 -> 16'h035f và 8'h98 -> 16'hef5c.
- 5 ca reset bất đồng bộ mức thấp giữa các pha và phục hồi khung sau reset.
- 2 khung với enable giữ cao qua hoàn tất: lần nhận kế tiếp tại N+18.
- Kiểm tra enable trong khi xử lý, thay đổi bus sau chốt, độ trễ, xung
  output_done đúng một chu kỳ và giữ kết quả.
- Một DUT duy nhất, đọc symbol cố định từ trái sang phải.
- Oracle xét đủ codebook; khi hòa, ưu tiên byte có giá trị đảo 8 bit nhỏ hơn,
  phù hợp với quy tắc chọn predecessor/state hiện có của RTL.
- 256 cặp file nhị phân mẫu pass 100%.
- Biên dịch `-g2001 -Wall -s viterbi_top -t null -c src/files.f` thành công,
  không có cảnh báo.

Testbench mới: tb/tb_viterbi_top.sv và tb/tb_viterbi_files.sv.
Chạy regression bằng scripts/run_tests.py. Log và verification_summary.json
của lần chạy này được lưu trong verification/; lần chạy mới tạo vào build/.

Chưa có input.txt/output.txt chính thức của giảng viên nên chưa kiểm tra
bộ dữ liệu đó. Kiểm thử exhaustive xác nhận nghiệm maximum-likelihood và
quy tắc hòa hiện có; không có nghĩa là sửa được mọi mẫu lỗi kênh.

Chưa xác nhận PPA bằng thư viện công nghệ hoặc sau layout. Clock 5 ns là
mục tiêu 200 MHz, không phải kết quả đo tần số, diện tích hoặc công suất.
Quy tắc đóng gói trong Specification/main.tex và README.md đã được cập nhật.
Các ảnh datapath cũ chưa vẽ lại: đường dịch K1 và vị trí ghi K7 cần được
đối chiếu với RTL mới. Hai chỗ chèn ảnh Hình 5 và Hình 6 vẫn được giữ nguyên.
