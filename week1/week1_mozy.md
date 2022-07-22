# BOOM LABS 1차 Todo (mozy)

<br />

## 과제1. 메타마스크 지갑 생성 / 메타마스크로 이더 송금

### 1. 거래소 지갑은 여러 블록체인 네트워크의 개인 키를 가지고 있는건가?

### 2. 처음에 업비트 거래소 서비스를 사용하여 이더를 옮기려고 하니 제약사항이 있어 빗썸 거래소를 사용하였다. 업비트 거래소가 아닌 `업비트 오픈 API`, `pyupbit`를 사용한다면 가능할까?

<<<<<<< HEAD
> 결론은 못했다....
=======
> 결론은 모른다... 포기...
>>>>>>> parent of 74bbf50... 20220722 | 1차 과제 | mozy

```python
import pyupbit

## 로그인
access = "73kVqowGQOGEjdR31221j31j2ifekjkgjekgjekg"          # 본인 값으로 변경
secret = "egjekgj3iekeEEkej3i3j3iejjwiEejiejeEeijg"          # 본인 값으로 변경
upbit = pyupbit.Upbit(access, secret)
```
```python
## 코인 출금 함수 : withdraw_coin
help(upbit.withdraw_coin)
```
```
Help on method withdraw_coin in module pyupbit.exchange_api:

withdraw_coin(currency, amount, address, secondary_address='None', transaction_type='default', contain_req=False) method of pyupbit.exchange_api.Upbit instance
    코인 출금
    :param currency: Currency symbol
    :param amount: 주문 가격
    :param address: 출금 지갑 주소
    :param secondary_address: 2차 출금주소 (필요한 코인에 한해서)
    :param transaction_type: 출금 유형
    :param contain_req: Remaining-Req 포함여부
    :return:
```
** 파라미터 의미를 알지못해 사용하지 못했다... `currency symbol`, `transaction_type` ?? **
### 3. 메타마스크 지갑에 연결시 패스워드를 입력한다. 어떤 방식(알고리즘, 사용되는 데이터)으로 키 정보를 만드는 걸까? (지난 수업 시간에 비대칭 알고리즘을 설명해 주셨는데...)

<br />

## 과제2. Ethereum → Polygon 옮기기

* Pending이 생각보다 오래걸린다.

* 이더리움 수수료/가스비가 진짜 비싸다...

> [Transaction Details](https://etherscan.io/tx/0x1833bb8418aa8111d7e9a8dd2f40c03356ea9e8cc001292dab783ab03f037a56)

[Uniswap V3 : Router 2](https://etherscan.io/address/0x68b3465833fb72a70ecdf485e0e4c7bd8665fc45) 스마트 컨트랙트를 사용하여 스왑

todo. 소스코드 분서...

<br />

## 과제3. Opensea 에서 Polygon 기반 NFT 구매 (optional)

<br />

## 과제4. Polygon 기반 Lending protocol으로 예치하고, 대출해보기

* metamask 에 mumbai 테스트넷 추가

* mumbai faucet
