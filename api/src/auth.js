// eslint-disable-next-line no-unused-vars
exports.authenticate = async function authenticate(req) {
  // Use token in cookie to determine who is making request
  // returns membership object if authenticated, throws 401 if not
  return {};
};

// eslint-disable-next-line no-unused-vars
exports.capabilities = async function capabilities(membership, resource) {
  // returns list of capabilities for the given resource
  return [];
};

exports.authorize = async function authorize(capability, membership, resource) {
  // returns true of authorized, false if not
  return exports.capabilities(membership, resource).includes(capability);
};
