const http = require('http');

console.log('Testing health endpoint...');

http.get('http://localhost:3000/health', (res) => {
  let data = '';
  res.on('data', (chunk) => data += chunk);
  res.on('end', () => {
    console.log('Health check result:', data);
    testRoutePlan();
  });
}).on('error', console.error);

function testRoutePlan() {
  console.log('\nTesting route plan endpoint...');

  const postData = JSON.stringify({
    start: '北京南站',
    end: '中关村'
  });

  const options = {
    hostname: 'localhost',
    port: 3000,
    path: '/api/route-plan/plan',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(postData)
    }
  };

  const req = http.request(options, (res) => {
    let responseData = '';
    res.on('data', (chunk) => responseData += chunk);
    res.on('end', () => {
      console.log('Route plan result:', responseData);
      testSubwayService();
    });
  });

  req.on('error', console.error);
  req.write(postData);
  req.end();
}

function testSubwayService() {
  console.log('\nTesting subway service endpoint...');

  http.get('http://localhost:3000/api/subway-service/station/1', (res) => {
    let data = '';
    res.on('data', (chunk) => data += chunk);
    res.on('end', () => {
      console.log('Subway service result:', data);
      testTravelAlerts();
    });
  }).on('error', console.error);
}

function testTravelAlerts() {
  console.log('\nTesting travel alerts endpoint...');

  http.get('http://localhost:3000/api/travel-alerts', (res) => {
    let data = '';
    res.on('data', (chunk) => data += chunk);
    res.on('end', () => {
      console.log('Travel alerts result:', data);
      console.log('\n✅ All tests completed!');
    });
  }).on('error', console.error);
}