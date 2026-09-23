const { createHash } = require('node:crypto');

function normaliseVpa(address) {
  return address.trim().toLowerCase();
}

function hashLoginPin(pin) {
  return createHash('sha256').update(pin).digest('hex');
}

const priyaVpa = {
  address: 'priya@paylite',
  verifiedName: 'Priya Sharma',
  bankName: 'PayLite Bank',
  accountId: 'account-primary',
};

const merchantVpa = {
  address: 'merchant@paylite',
  verifiedName: 'Merchant Store',
  bankName: 'PayLite Bank',
  accountId: 'account-merchant',
};

const rameshVpa = {
  address: 'ramesh@paylite',
  verifiedName: 'Ramesh Kumar',
  bankName: 'PayLite Bank',
  accountId: 'account-ramesh',
};

const ashaVpa = {
  address: 'asha@paylite',
  verifiedName: 'Asha Rao',
  bankName: 'PayLite Bank',
  accountId: 'account-asha',
};

const store = {
  customers: new Map([
    [
      'CUST1001',
      {
        id: 'CUST1001',
        loginPinHash: hashLoginPin('1234'),
        accountId: 'account-primary',
        boundDeviceId: null,
      },
    ],
  ]),
  accounts: new Map([
    [
      'account-primary',
      {
        id: 'account-primary',
        maskedNumber: 'XXXX 4821',
        balancePaise: 2500000,
        primaryVpa: priyaVpa.address,
      },
    ],
  ]),
  vpas: new Map(
    [priyaVpa, merchantVpa, rameshVpa, ashaVpa].map((vpa) => [
      normaliseVpa(vpa.address),
      vpa,
    ]),
  ),
  payments: [
    {
      id: 'pay_seed_001',
      accountId: 'account-primary',
      direction: 'SENT',
      counterparty: merchantVpa,
      amountPaise: 12500,
      note: 'Groceries',
      status: 'SUCCESS',
      upiRef: 'PL202609220001',
      createdAt: '2026-09-21T09:00:00.000Z',
      pendingUntil: null,
    },
    {
      id: 'pay_seed_002',
      accountId: 'account-primary',
      direction: 'RECEIVED',
      counterparty: rameshVpa,
      amountPaise: 8000,
      note: 'Lunch split',
      status: 'SUCCESS',
      upiRef: 'PL202609210002',
      createdAt: '2026-09-20T14:30:00.000Z',
      pendingUntil: null,
    },
  ],
  sessions: new Map(),
  idempotencyRecords: new Map(),
};

module.exports = { hashLoginPin, normaliseVpa, store };
