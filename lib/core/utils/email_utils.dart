String normalizeEmail(String email) => email.trim().toLowerCase();

String inviteDocumentId(String email) => normalizeEmail(email);
