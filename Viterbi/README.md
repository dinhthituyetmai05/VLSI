# Bộ giải mã Viterbi theo Requirements.pdf

Bản RTL dành cho mã chập K=3, R=1/2, đa thức sinh (7,5) hệ bát phân.
Mỗi khung nhận 16 bit mã hóa và trả 8 bit thông tin. Mã nguồn dùng Verilog-2001;
testbench dùng SystemVerilog. Các comment trong RTL dùng tiếng Anh để tránh lỗi
encoding giữa các công cụ EDA.

## Cấu hình và thuật toán

| Thuộc tính | Giá trị |
| --- | --- |
| Bit thông tin mỗi bước | 1 |
| Bit mã hóa mỗi bước | 2 |
| Constraint length | K=3 |
| Số bit nhớ | K-1=2 |
| Số trạng thái | 4 |
| Đa thức sinh | v1=u XOR a XOR b; v2=u XOR b |
| Trạng thái hiện tại | {a,b} = {bit mới nhất, bit cũ hơn} |
| Trạng thái tiếp theo | {u,a} |
| Trạng thái đầu mỗi khung | 00 |
| Trạng thái cuối | Chọn metric nhỏ nhất trong 4 trạng thái |
| Chiều dài khung | 8 bước, không thêm tail bit |
| Path metric | 5 bit; 31 biểu diễn không thể tới |
| Survivor memory | 8 bước x 4 quyết định = 32 bit |

Không dùng lại m=3 của code cũ: đó là 3 bit nhớ/8 trạng thái, khác với K=3
trong đề. Với khung 8 bước, giới hạn tổng khoảng cách Hamming là 16; dùng
5 bit để biểu diễn miền hữu hạn này và giá trị vô cực riêng, không cần chuẩn
hóa metric giữa khung. ACS dùng phép cộng mở rộng và bão hòa để tránh tràn.

Mỗi bước tính đồng thời metric cho cả 4 trạng thái. Khi hai đường đi đến
cùng trạng thái, giữ đường có metric nhỏ hơn; hòa thì chọn predecessor có
bit nhớ cũ bằng 0. Sau bước thứ 8, chọn trạng thái cuối bằng cây so sánh cân
bằng (hòa thì chọn số trạng thái nhỏ hơn). Truy vết đủ 8 bước.

## Phân chia module

`viterbi_top.v` chỉ khai báo dây nối và instantiate bốn module con:
`viterbi_control`, `viterbi_branch_metrics`, `viterbi_acs_unit` và
`viterbi_best_state`. Top không chứa FSM, thanh ghi hoặc khối `always`.

`viterbi_control.v` quản lý FSM, thanh ghi đầu vào, path metric, survivor
memory, truy vết và thanh ghi đầu ra. Khối này cấp cặp nhận/metric hiện tại
cho datapath và chốt kết quả ACS. Cách tách module không thêm thanh ghi,
giữ nguyên độ trễ giải mã. Giao tiếp top hiện dùng đúng sáu cổng của đề.

## Giao tiếp top `viterbi_top`

| Cổng | Chiều | Ý nghĩa |
| --- | --- | --- |
| clk | vào | Clock cạnh lên |
| rstn | vào | Reset bất đồng bộ, tích cực mức 0 |
| viterbi_enable | vào | Chấp nhận khung tại cạnh lên khi FSM ở IDLE |
| input_data[15:0] | vào | Toàn bộ khung; được chốt lúc chấp nhận viterbi_enable |
| output_data[7:0] | ra | Kết quả; giữ ổn định đến kết quả kế tiếp hoặc khi rstn=0 |
| output_done | ra | Xung 1 chu kỳ khi output_data hợp lệ |

`viterbi_enable` trong lúc đang xử lý khung bị bỏ qua. Đầu vào có thể đổi sau cạnh nhận khung.
Nếu giữ `viterbi_enable=1`, một khung mới sẽ được chấp nhận ở cạnh đầu tiên sau khi
FSM trở về IDLE (cạnh sau xung `output_done`). `rstn=0` hủy khung đang xử lý, xóa output_done và kết quả. Các khung độc lập:
trạng thái mã hóa được giả định trở về 00 ở đầu mỗi khung.

Nếu nhận khung ở cạnh N:

| Cạnh clock | Công việc |
| --- | --- |
| N | Chốt dữ liệu và khởi tạo metric |
| N+1 đến N+8 | Tính BM/ACS, lưu survivor |
| N+9 | Chọn trạng thái cuối |
| N+10 đến N+17 | Truy vết; phát output_done tại N+17 |
| N+18 | Có thể nhận khung tiếp theo |

Độ trễ là 17 chu kỳ sau cạnh nhận khung; khoảng cách nhận khung tối thiểu
là 18 chu kỳ. Ở 200 MHz, hai giá trị tương ứng là 85 ns và 90 ns. Đây là tính
toán theo giao thức, không phải kết quả đo timing vật lý.

## Thứ tự bit

Thứ tự được cố định từ trái sang phải, không có tham số chọn chiều đọc:

- Tám symbol lần lượt là input_data[15:14], [13:12], [11:10], [9:8],
  [7:6], [5:4], [3:2], [1:0].
- Tám bit thông tin theo thời gian nằm ở output_data[7] đến output_data[0].
- Trong mỗi cặp `{v1,v2}`, v1 ở bit cao và v2 ở bit thấp.
- Thanh ghi khung dịch trái 2 bit sau mỗi lần cập nhật metric.
- Traceback đọc lịch sử từ bước 7 về 0, nên ghi bộ đệm từ bit 0 lên bit 7.

Ví dụ: byte `8'h19` (00011001) mã hóa thành `16'h035f`.
Chuỗi 10011000 (`8'h98`) tạo các symbol 11, 10, 11, 11, 01, 01, 11, 00,
được đóng gói thành `16'hef5c`.

## Các file và ánh xạ từ code cũ

| File cũ | File mới / thay đổi |
| --- | --- |
| bVITERBI_213.v | src/viterbi_top.v: top cấu trúc, nối các module con |
| bBMU_213.v | src/viterbi_branch_metrics.v: dùng chung 4 khoảng cách Hamming |
| bACS_213.v | src/viterbi_acs.v: ACS tổ hợp, cộng bão hòa, hòa xác định |
| bACSU_213.v | src/viterbi_acs_unit.v: 4 ACS, trellis đúng cho (7,5) |
| bCONTROL_213.v | src/viterbi_control.v: FSM/metric/survivor/traceback |
| bTBDECISION_213.v | src/viterbi_best_state.v: chọn trong 4 trạng thái |
| bSYNCERR_213.v | Loại bỏ: so sánh chỉ số trạng thái không phát hiện được lỗi giải mã |
| params_b213.inc.v | Hằng số cục bộ, bỏ macro tên ngắn dùng chung toàn dự án |

Bản đối chiếu ban đầu được đọc từ
`E:\Hust document\VLSI\VLSI\Viterbi\src`. Bản sửa được phát triển và kiểm
thử trong workspace đang mở, sau đó đồng bộ về dự án gốc ở ổ E. Mã cũ
được giữ trong reference/original_src để đối chiếu hoặc khôi phục. Vì workspace
ban đầu chưa có src, Git hiển thị các file mới thay vì một diff đổi tên.

Đây là thay đổi giao tiếp top: cần sửa nơi instantiate module cũ. Không còn
Rx 2 bit, Dx 1 bit, oe, seq_ready hoặc sync_error. `busy` đã được bỏ khỏi top và controller: đây chỉ là cờ trạng thái,
không quyết định việc nhận khung. Sau khi nhả reset hoặc thấy `output_done=1`,
bên gửi đặt dữ liệu và phát enable; dữ liệu khung mới được chốt tại cạnh lên
kế tiếp khi FSM ở IDLE. `output_done` báo kết quả đã có,
không phải chứng nhận đã sửa đúng mọi lỗi kênh. Khi có nhiều bản tin gần
nhất như nhau, bộ giải mã trả một nghiệm theo quy tắc hòa đã định.

## Chạy kiểm thử

Cần Python 3.10+ và Icarus Verilog (`iverilog`, `vvp`). Chạy từ gốc dự án:

```powershell
python scripts/run_tests.py
```

Nếu dùng bản công cụ cục bộ đã giải nén trong workspace:

```powershell
python scripts/run_tests.py --iverilog .tools/iverilog/app/bin/iverilog.exe --vvp .tools/iverilog/app/bin/vvp.exe
```

Script tự sinh oracle bằng cách mã hóa đủ 256 bản tin theo công thức đa thức,
rồi duyệt toàn bộ codebook để tìm khoảng cách Hamming nhỏ nhất cho từng
giá trị nhận 16 bit. Oracle không dùng lại trellis/ACS của DUT. Nếu hòa,
ưu tiên byte có giá trị đảo thứ tự 8 bit nhỏ nhất, tương đương quy tắc
hòa predecessor/state hiện có của RTL khi đọc từ trái sang phải.

Testbench kiểm tra:

- Tất cả 65.536 từ nhận, gồm cả dữ liệu lỗi và trường hợp hòa, theo thứ tự cố định từ trái sang phải.
- Cả 256 bản tin sạch và ví dụ mã hóa trong tài liệu.
- Enable khi đang xử lý, thay đổi bus sau chốt, độ trễ, xung output_done, giữ kết quả.
- Giữ enable qua thời điểm hoàn tất: nhận khung kế tiếp tại N+18.
- Reset giữa giải mã, chọn trạng thái cuối và truy vết; khung tiếp theo phải đúng.
- Giao tiếp file với 256 cặp dữ liệu mẫu sinh riêng trong build/.

Để chạy thêm cặp file của đề:

```powershell
python scripts/run_tests.py --encoded "duong_dan/output.txt" --expected "duong_dan/input.txt"
```

Mỗi từ là chuỗi nhị phân đúng 16/8 ký tự, không có tiền tố hoặc comment.
Hai file phải có cùng số từ và không được rỗng. `tb_viterbi_files.sv` dùng
mặc định tên output.txt/input.txt; có thể truyền +ENCODED=... và +EXPECTED=...
khi chạy vvp. File dữ liệu mã hóa được đọc theo thứ tự từ trái sang phải,
mỗi lần lấy một cặp 2 bit. Không có tùy chọn đổi thứ tự bit.

File log và verification_summary.json nằm trong build/. Dữ liệu mẫu không
được coi là dữ liệu chính thức của giảng viên.

## Tổng hợp và PPA

Danh sách RTL: src/files.f. Top: viterbi_top. Tất cả module trong src/
đều dùng RTL tổng hợp được, không có delay, initial hoặc tri-state nội bộ.
Để tổng hợp chỉ nạp các file RTL, không nạp tb/.

constraints/viterbi_top.sdc đặt clock 5 ns (200 MHz). Phải bổ sung I/O
delay, tải, driving cell, clock uncertainty và ràng buộc rstn theo flow thực tế.
Không đặt false path rộng để che đường timing của dữ liệu.

Các yêu cầu f >= 200 MHz, diện tích <= 7000 um^2, công suất <= 1.5 mW cần
xác nhận bằng thư viện cell, PVT corner, hoạt động chuyển mạch và báo cáo
sau layout. Chạy mô phỏng với clock 5 ns chỉ xác nhận giao thức chức năng.
Workspace hiện chưa có PDK/thư viện và flow layout nên chưa xác nhận PPA.
