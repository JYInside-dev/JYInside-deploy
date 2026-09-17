import http from 'k6/http';
import { check, sleep } from 'k6';

const BASE_URL = __ENV.BASE_URL || 'http://nginx:80';
const BOARD_PATH = __ENV.BOARD_PATH || 'test';
const CATEGORY_ID = __ENV.CATEGORY_ID ? Number(__ENV.CATEGORY_ID) : null;
const PASSWORD = __ENV.POST_PASSWORD || '1234';
const RESULT_PREFIX = __ENV.RESULT_PREFIX || 'post-write';

export const options = {
    stages: [
        { duration: '30s', target: 10 },
        { duration: '1m', target: 10 },
        { duration: '30s', target: 0 },
    ],
    summaryTrendStats: ['avg', 'min', 'med', 'p(90)', 'p(95)', 'p(99)', 'max'],
    thresholds: {
        http_req_failed: ['rate<0.01'],
        'http_req_duration{endpoint:post-write}': ['p(95)<1000'],
    },
};

export default function () {
    const unique = `${__VU}-${__ITER}-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;

    const payload = JSON.stringify({
        title: `k6 글 작성 테스트 ${unique}`,
        content: `k6로 생성한 부하 테스트 게시글입니다.\nunique=${unique}`,
        authorName: `k6-user-${__VU}`,
        password: PASSWORD,
        categoryId: CATEGORY_ID,
    });

    const params = {
        headers: {
            'Content-Type': 'application/json',
        },
        tags: {
            endpoint: 'post-write',
        },
    };

    if (__ENV.AUTH_TOKEN) {
        params.headers.Authorization = `Bearer ${__ENV.AUTH_TOKEN}`;
    }

    const res = http.post(
        `${BASE_URL}/api/community/board/${BOARD_PATH}/write`,
        payload,
        params
    );

    check(res, {
        'status is 201': (r) => r.status === 201,
    });

    if (res.status !== 201 && __ITER < 3) {
        console.error(`write failed: status=${res.status}, body=${res.body}`);
    }

    sleep(1);
}

export function handleSummary(data) {
    return {
        [`/results/${RESULT_PREFIX}-summary.json`]: JSON.stringify(data, null, 2),
    };
}