exports.schema = `
paths:
  /:
    get:
      operationId: index
`;

exports.index = async () => {
  return { ok: true };
};
