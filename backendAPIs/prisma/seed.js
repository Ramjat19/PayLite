const { PrismaClient } = require('@prisma/client');
const { createHash } = require('node:crypto');

const prisma = new PrismaClient();
const hash = (value) => createHash('sha256').update(value).digest('hex');

async function main() {
  await prisma.customer.upsert({
    where: { id: 'CUST1001' },
    update: {},
    create: {
      id: 'CUST1001',
      loginPinHash: hash('1234'),
      paymentPinHash: hash('1234'),
      account: {
        create: {
          id: 'account-primary',
          maskedNumber: 'XXXX 4821',
          balancePaise: 2500000,
          primaryVpaAddress: 'priya@paylite',
          vpas: {
            create: {
              address: 'priya@paylite',
              normalizedAddress: 'priya@paylite',
              verifiedName: 'Priya Sharma',
              bankName: 'PayLite Bank',
            },
          },
        },
      },
    },
  });

  const vpas = [
    ['merchant@paylite', 'Merchant Store', 'account-merchant'],
    ['ramesh@paylite', 'Ramesh Kumar', 'account-ramesh'],
    ['asha@paylite', 'Asha Rao', 'account-asha'],
  ];
  for (const [address, verifiedName, accountId] of vpas) {
    await prisma.account.upsert({
      where: { id: accountId },
      update: {},
      create: {
        id: accountId,
        customerId: `seed-${accountId}`,
        maskedNumber: 'XXXX 0000',
        balancePaise: 0,
        primaryVpaAddress: address,
        customer: {
          create: {
            id: `seed-${accountId}`,
            loginPinHash: hash('1234'),
            paymentPinHash: hash('1234'),
          },
        },
        vpas: { create: { address, normalizedAddress: address, verifiedName, bankName: 'PayLite Bank' } },
      },
    });
  }
}

main().finally(() => prisma.$disconnect());