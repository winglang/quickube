bring "./sim.w" as sim;
bring cloud;
bring expect;

let dns = new sim.DnsSimulation();

test "create a record" {
  dns.addARecord("bing", "1.2.3.4");
}

test "remove a record" {
  dns.removeARecord("bing", "1.2.3.4");
}

test "find a record" {
  let record = dns.tryFindARecord("bing");
  expect.nil(record);
}
