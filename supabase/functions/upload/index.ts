// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

// Setup type definitions for built-in Supabase Runtime APIs
import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { S3Client, PutObjectCommand } from 'npm:@aws-sdk/client-s3@3'

console.log("Hello from Functions!")

Deno.serve(async (req) => {
  try {
    const formData = await req.formData();
    const file = formData.get('file') as File | null;
    const key = formData.get('key') as string || `uploads/${file?.name || 'unknown'}`;

    if (!file) {
      return new Response(JSON.stringify({ error: 'No file provided' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    const r2Endpoint = `https://${Deno.env.get('R2_ACCOUNT_ID')}.r2.cloudflarestorage.com`;
    const bucketName = Deno.env.get('R2_BUCKET_NAME')!;
    const region = 'auto';

    const s3Client = new S3Client({
      region,
      endpoint: r2Endpoint,
      credentials: {
        accessKeyId: Deno.env.get('R2_ACCESS_KEY_ID')!,
        secretAccessKey: Deno.env.get('R2_SECRET_ACCESS_KEY')!,
      },
      forcePathStyle: false,
    });

    const arrayBuffer = await file.arrayBuffer();
    const body = new Uint8Array(arrayBuffer);

    const uploadParams = {
      Bucket: bucketName,
      Key: key,
      Body: body,
      ContentType: file.type || 'application/octet-stream',
    };

    const command = new PutObjectCommand(uploadParams);
    await s3Client.send(command);

    const publicUrl = `https://${Deno.env.get('R2_PUBLIC_BUCKET_URL') || bucketName}.r2.dev/${key}`;

    return new Response(JSON.stringify({ success: true, publicUrl }), {
      headers: { 'Content-Type': 'application/json' },
    });

  } catch (error) {
    console.error(error);
    return new Response(JSON.stringify({ success: false, error: 'Upload failed', details: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
})
