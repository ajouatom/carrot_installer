### carrot installer
* 준비물
  * 콤마 C3 또는 C4: wifi 또는 hotspot연결
  * windows pc : 같은 네트워크에 연결
  * 파일 다운로드: https://github.com/ajouatom/carrot_installer/archive/refs/heads/master.zip
* 콤마준비: 리셋
  * 새재품은 USB공급, 사용하던것은 부팅시 화면 연속터치
  * Wifi setup : ssid선택후 비밀번호 입력
  * Next누르고 대기
* 윈도우설치과정
  * 명령프롬프트(Command prompt)실행
  * 다운로드한 폴더로 이동
  * install.bat(콤마ip를 알고 있는경우) 또는 install_auto.bat(ip를 모르는 경우) 실행
  * ip대역입력: 192.168.0(로컬IP가 192.168.0.xx 인경우), 192.168.1(로컬IP가 192.168.1.xx인경우)
  * branch명 입력: c3-v10-wip 와 같이 입력, c3인지 c4인지 반드시 확인함. https://github.com/ajouatom/openpilot 에서 확인
    prebuilt된 branch를 선택하면, 빌드없이 바로 사용가능
    <img width="660" height="271" alt="스크린샷 2026-03-22 191633" src="https://github.com/user-attachments/assets/4ec37721-829b-42d6-98a0-b756f9b61123" />
  * install_auto.bat의 경우 ip자동검색(시간이 걸릴수도 있음)후 설치시작됨.
    <img width="654" height="482" alt="스크린샷 2026-03-22 191647" src="https://github.com/user-attachments/assets/e627af75-7c87-48df-b7e2-0805b661526d" />

  * 아래의 화면이 나오면 정상작동중임.
    <img width="749" height="507" alt="스크린샷 2026-03-23 141131" src="https://github.com/user-attachments/assets/3ec5d427-cac0-48a0-ae9a-4795079a3c78" />
