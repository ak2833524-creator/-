-- ==============================================================================
-- 노인맞춤돌봄서비스 생활지원사 12인 통합 관리대장 - Supabase 데이터베이스 스키마
-- Supabase SQL Editor에 붙여넣어 실행(Run)하세요.
-- ==============================================================================

-- 1. 생활지원사 테이블 (care_workers)
CREATE TABLE IF NOT EXISTS public.care_workers (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    phone TEXT,
    area TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT '정상근무',
    focus_count INTEGER NOT NULL DEFAULT 2,
    normal_count INTEGER NOT NULL DEFAULT 14,
    substitute_id INTEGER REFERENCES public.care_workers(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. 관리 대상 어르신 테이블 (care_seniors)
CREATE TABLE IF NOT EXISTS public.care_seniors (
    id BIGSERIAL PRIMARY KEY,
    worker_id INTEGER REFERENCES public.care_workers(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('중점돌봄', '일반돌봄')),
    phone TEXT,
    emergency TEXT,
    address TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. 어르신 특이사항 보고 및 조치대장 테이블 (care_reports)
CREATE TABLE IF NOT EXISTS public.care_reports (
    id BIGSERIAL PRIMARY KEY,
    report_date TEXT NOT NULL,
    worker_id INTEGER REFERENCES public.care_workers(id) ON DELETE CASCADE,
    senior_id BIGINT REFERENCES public.care_seniors(id) ON DELETE SET NULL,
    category TEXT NOT NULL,
    urgency TEXT NOT NULL CHECK (urgency IN ('주의/요관찰', '긴급/응급', '일반')),
    content TEXT NOT NULL,
    action TEXT,
    status TEXT NOT NULL DEFAULT '조치중' CHECK (status IN ('조치중', '조치완료', '접수')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. 휴가 및 대체인력 관리대장 테이블 (care_leaves)
CREATE TABLE IF NOT EXISTS public.care_leaves (
    id BIGSERIAL PRIMARY KEY,
    request_date TEXT NOT NULL,
    worker_id INTEGER REFERENCES public.care_workers(id) ON DELETE CASCADE,
    leave_type TEXT NOT NULL,
    start_date TEXT NOT NULL,
    end_date TEXT NOT NULL,
    days NUMERIC(3, 1) NOT NULL DEFAULT 1.0,
    reason TEXT NOT NULL,
    substitute_id INTEGER REFERENCES public.care_workers(id) ON DELETE SET NULL,
    plan TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT '승인대기' CHECK (status IN ('승인대기', '승인완료', '반려')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 인덱스 생성 (성능 최적화)
CREATE INDEX IF NOT EXISTS idx_seniors_worker_id ON public.care_seniors(worker_id);
CREATE INDEX IF NOT EXISTS idx_reports_worker_id ON public.care_reports(worker_id);
CREATE INDEX IF NOT EXISTS idx_reports_senior_id ON public.care_reports(senior_id);
CREATE INDEX IF NOT EXISTS idx_leaves_worker_id ON public.care_leaves(worker_id);

-- ==============================================================================
-- Row Level Security (RLS) 설정
-- 웹 프론트엔드(Anon Key)에서 읽기/쓰기가 가능하도록 정책을 활성화합니다.
-- ==============================================================================
ALTER TABLE public.care_workers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.care_seniors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.care_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.care_leaves ENABLE ROW LEVEL SECURITY;

-- 기존 정책이 있을 경우를 대비해 DROP 후 재생성
DROP POLICY IF EXISTS "Public full access on care_workers" ON public.care_workers;
CREATE POLICY "Public full access on care_workers" ON public.care_workers FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Public full access on care_seniors" ON public.care_seniors;
CREATE POLICY "Public full access on care_seniors" ON public.care_seniors FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Public full access on care_reports" ON public.care_reports;
CREATE POLICY "Public full access on care_reports" ON public.care_reports FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Public full access on care_leaves" ON public.care_leaves;
CREATE POLICY "Public full access on care_leaves" ON public.care_leaves FOR ALL USING (true) WITH CHECK (true);

-- ==============================================================================
-- 초기 샘플 데이터 입력 (Seed Data)
-- ==============================================================================

-- 12인 생활지원사 초기 데이터
INSERT INTO public.care_workers (id, name, phone, area, status, focus_count, normal_count, substitute_id)
OVERRIDING SYSTEM VALUE
VALUES
  (1, '김영순', '010-3451-2001', '1권역 (행복1동)', '정상근무', 2, 14, 2),
  (2, '이정숙', '010-4822-2002', '1권역 (행복2동)', '정상근무', 2, 14, 1),
  (3, '박미경', '010-9182-2003', '2권역 (희망1동)', '정상근무', 2, 14, 4),
  (4, '최순자', '010-2931-2004', '2권역 (희망2동)', '정상근무', 2, 14, 3),
  (5, '정영희', '010-8472-2005', '3권역 (평화1동)', '정상근무', 2, 14, 6),
  (6, '강정순', '010-5321-2006', '3권역 (평화2동)', '휴가중', 2, 14, 5),
  (7, '조옥자', '010-7712-2007', '4권역 (나눔1동)', '정상근무', 2, 14, 8),
  (8, '윤명숙', '010-6192-2008', '4권역 (나눔2동)', '정상근무', 2, 14, 7),
  (9, '한경희', '010-3841-2009', '5권역 (사랑1동)', '정상근무', 2, 14, 10),
  (10, '오미자', '010-4211-2010', '5권역 (사랑2동)', '정상근무', 2, 14, 9),
  (11, '송혜숙', '010-9012-2011', '6권역 (온유1동)', '정상근무', 2, 14, 12),
  (12, '임복순', '010-8231-2012', '6권역 (온유2동)', '정상근무', 2, 14, 11)
ON CONFLICT (id) DO NOTHING;

-- 시퀀스 최신화
SELECT setval('care_workers_id_seq', (SELECT MAX(id) FROM public.care_workers));

-- 대상 어르신 샘플 데이터
INSERT INTO public.care_seniors (id, worker_id, name, type, phone, address, emergency, notes)
OVERRIDING SYSTEM VALUE
VALUES
  (101, 1, '박순옥', '중점돌봄', '010-2345-0001', '행복1동 102호', '010-9988-1122 (장남)', '관절염 중증, 보행보조기 필수, 당뇨 식단관리 필요'),
  (102, 1, '이종태', '중점돌봄', '010-2345-0002', '행복1동 305호', '010-8877-2233 (딸)', '독거, 경증 인지저하, 가스밸브 자동잠금기 점검 필요'),
  (103, 1, '정말순', '일반돌봄', '010-2345-0003', '행복1동 201호', '010-7766-3344 (이웃)', '고혈압 약 복용, 말벗 선호'),
  (104, 1, '김봉출', '일반돌봄', '010-2345-0004', '행복1동 402호', '010-6655-4455 (조카)', '청력 저하, 큰 목소리로 소통 필요'),
  (105, 2, '최길자', '중점돌봄', '010-3456-0005', '행복2동 101호', '010-5544-5566 (딸)', '뇌졸중 후유증 편마비, 욕창 예방 자세 안내'),
  (106, 2, '조동일', '중점돌봄', '010-3456-0006', '행복2동 204호', '010-4433-6677 (아들)', '심혈관 질환, 주 2회 병원투약 확인 필수'),
  (107, 3, '황복남', '중점돌봄', '010-4567-0008', '희망1동 104호', '010-2211-8899 (사위)', '우울증 약물 복용, 식사 거름 잦음, 정서지지 필요'),
  (108, 3, '손정식', '중점돌봄', '010-4567-0009', '희망1동 502호', '010-1100-9900 (요양보호사)', '거동불가 와상, 기저귀 및 식사 확인'),
  (109, 4, '배춘자', '중점돌봄', '010-5678-0010', '희망2동 203호', '010-9087-0011 (딸)', '척추협착증, 낙상위험군 주의'),
  (110, 5, '문수길', '중점돌봄', '010-6789-0011', '평화1동 103호', '010-8976-0022 (아들)', '당뇨 합병증, 발 상처 확인 필요'),
  (111, 6, '양금순', '중점돌봄', '010-7890-0012', '평화2동 401호', '010-7865-0033 (장녀)', '강정순 지원사 휴가중 -> 정영희 지원사가 대체방문 중'),
  (112, 7, '서만석', '중점돌봄', '010-8901-0013', '나눔1동 302호', '010-6754-0044 (조카)', '만성폐쇄성폐질환(COPD), 호흡곤란 관찰'),
  (113, 8, '전옥분', '중점돌봄', '010-9012-0014', '나눔2동 202호', '010-5643-0055 (딸)', '고독사 위험군, 일일 안부확인 철저'),
  (114, 9, '노진구', '중점돌봄', '010-0123-0015', '사랑1동 101호', '010-4532-0066 (이웃)', '알코올 의존 경향, 방문 시 영양음료 전달'),
  (115, 10, '구영모', '중점돌봄', '010-1234-0016', '사랑2동 503호', '010-3421-0077 (아들)', '파킨슨병, 떨림 증상 심함'),
  (116, 11, '안순자', '중점돌봄', '010-2345-0017', '온유1동 204호', '010-2310-0088 (딸)', '골다공증 심함, 욕실 미끄럼방지매트 설치 완료'),
  (117, 12, '오갑순', '중점돌봄', '010-3456-0018', '온유2동 301호', '010-1209-0099 (아들)', '치매 전단계, 약 달력 복용 확인 요망')
ON CONFLICT (id) DO NOTHING;

SELECT setval('care_seniors_id_seq', (SELECT MAX(id) FROM public.care_seniors));

-- 특이사항 보고 샘플 데이터
INSERT INTO public.care_reports (id, report_date, worker_id, senior_id, category, urgency, content, action, status)
OVERRIDING SYSTEM VALUE
VALUES
  (1, '2026-10-08 09:30', 1, 101, '건강악화/병원동행', '주의/요관찰', '무릎 관절 부종 심화로 보행 시 통증 호소. 식사 준비 어려움.', '전담사회복지사 보고 후 인근 정형외과 동행 연계. 밑반찬 지원 요청.', '조치중'),
  (2, '2026-10-07 14:15', 3, 107, '영양/식사불량', '주의/요관찰', '최근 3일간 식사 거름 및 냉장고 상한 음식 방치됨.', '상한 음식 폐기, 죽 배달 연계 및 영양제 전달.', '조치중'),
  (3, '2026-10-06 11:20', 2, 105, '응급이송/낙상', '긴급/응급', '화장실 앞 바닥 낙상 발견, 엉덩이 타박상.', '119 응급실 이송, 엑스레이 골절 없음 확인, 가족 인계 완료.', '조치완료'),
  (4, '2026-10-05 16:00', 5, 110, '건강악화/병원동행', '주의/요관찰', '우측 발가락 궤양 증상 악화 조짐.', '보호자 유선 연락 후 토요일 전문병원 동행 확정.', '조치완료'),
  (5, '2026-10-04 10:40', 7, 112, '주거위험/환경개선', '일반', '보일러 온수 고장 냉방 생활.', '주민센터 긴급 에너지바우처 및 무상점검 신청 연계.', '조치완료'),
  (6, '2026-10-02 13:50', 4, 109, '연락두절/안전의심', '긴급/응급', '안부전화 3회 미수신. 긴급 현장방문.', '경로당 마실 확인됨. 휴대폰 충전방법 재안내.', '조치완료'),
  (7, '2026-09-29 15:10', 9, 114, '심리불안/우울', '일반', '명절 이후 고독감 및 우울감 호소.', '정서적 지지 및 복지관 원예 프로그램 참여 연계.', '조치완료'),
  (8, '2026-09-25 11:00', 12, 117, '기타특이사항', '일반', '처방약 중복 복용 위험 발견.', '요일별 약 달력 교체 부착 및 복약 지도 완료.', '조치완료')
ON CONFLICT (id) DO NOTHING;

SELECT setval('care_reports_id_seq', (SELECT MAX(id) FROM public.care_reports));

-- 휴가 및 대체인력 샘플 데이터
INSERT INTO public.care_leaves (id, request_date, worker_id, leave_type, start_date, end_date, days, reason, substitute_id, plan, status)
OVERRIDING SYSTEM VALUE
VALUES
  (1, '2026-10-06', 6, '연차', '2026-10-08', '2026-10-08', 1.0, '가족 건강검진 동행', 5, '정영희 지원사가 평화2동 중점 2명 직접 방문 및 일반 14명 유선 확인', '승인완료'),
  (2, '2026-10-07', 2, '오후반차', '2026-10-12', '2026-10-12', 0.5, '개인 관공서 업무', 1, '오전 중점가구 방문 후 오후 유선 연락건 김영순 지원사 대행', '승인완료'),
  (3, '2026-10-08', 9, '연차', '2026-10-15', '2026-10-16', 2.0, '자녀 결혼식 관련 행사', 10, '오미자 지원사가 사랑1동 긴급 가구 현장점검 진행', '승인대기'),
  (4, '2026-09-20', 4, '병가', '2026-09-22', '2026-09-23', 2.0, '독감으로 인한 병원 치료', 3, '박미경 지원사가 희망2동 중점 2가구 집중 대리 순회', '승인완료')
ON CONFLICT (id) DO NOTHING;

SELECT setval('care_leaves_id_seq', (SELECT MAX(id) FROM public.care_leaves));

-- Realtime 기능 활성화 (선택 사항: 변경 사항 실시간 구독)
ALTER PUBLICATION supabase_realtime ADD TABLE public.care_workers;
ALTER PUBLICATION supabase_realtime ADD TABLE public.care_seniors;
ALTER PUBLICATION supabase_realtime ADD TABLE public.care_reports;
ALTER PUBLICATION supabase_realtime ADD TABLE public.care_leaves;
