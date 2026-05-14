async function addReputation(query, userId, amount, reason) {
  const result = await query(
    `UPDATE users SET reputation = reputation + $1 WHERE id = $2 RETURNING reputation`,
    [amount, userId]
  );
  const newRep = result.rows[0]?.reputation ?? 0;
  console.log(`[reputation] ${userId}: ${reason} → +${amount} (total: ${newRep})`);
  return newRep;
}

module.exports = { addReputation };
