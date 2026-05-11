module.exports = {
  registerMediaRoutes,
};

async function registerMediaRoutes({ req, pathname, user, json, badRequest, unauthorized }) {
  // POST /api/media/upload
  if (req.method === 'POST' && pathname === '/api/media/upload') {
    if (!user) return unauthorized(res, 'Not authenticated');

    try {
      const contentType = req.headers['content-type'] || '';
      if (!contentType.includes('multipart/form-data')) {
        return badRequest(res, 'Content-Type must be multipart/form-data');
      }

      // For demo: return mock upload response
      // Production: use multer/formidable to handle file upload
      const id = `m${Date.now()}${Math.floor(Math.random() * 1000)}`;
      const timestamp = Date.now();
      const mockUrl = `/uploads/media/${id}_${timestamp}.jpg`;

      return json(res, 201, {
        id,
        url: mockUrl,
        thumbnailUrl: mockUrl,
        message: 'Media upload endpoint ready. Configure multer for actual file handling.',
      });
    } catch (e) {
      console.error('Media upload error:', e);
      return badRequest(res, 'Failed to upload media');
    }
  }

  return false;
}
