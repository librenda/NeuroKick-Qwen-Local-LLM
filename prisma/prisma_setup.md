*1. Setup Requirements for running PRISMA:*
# 1. Setup TimescaleDB (5 minutes)
docker run -d --name timescale -p 5432:5432 -e POSTGRES_PASSWORD=password timescale/timescaledb:latest-pg14

# 2. Setup Qdrant (2 minutes)
docker run -d --name qdrant -p 6333:6333 qdrant/qdrant

# 3. Initialize Prisma (3 minutes)
npm install prisma @prisma/client
npx prisma init

*2. Setup .env:*

Step 1: Create the file in your root directory:
touch .env

Step 2: Add this content to .env:

*for seeing which version!*
npx prisma --version

*run prisma*
npx prisma dev

*To connect to your local Prisma Postgres database via Prisma ORM, use the following connection string:*
  
      DATABASE_URL="prisma+postgres://localhost:51213/?api_key=eyJkYXRhYmFzZVVybCI6InBvc3RncmVzOi8vcG9zdGdyZXM6cG9zdGdyZXNAbG9jYWxob3N0OjUxMjE0L3RlbXBsYXRlMT9jb25uZWN0aW9uX2xpbWl0PTEmY29ubmVjdF90aW1lb3V0PTAmbWF4X2lkbGVfY29ubmVjdGlvbl9saWZldGltZT0wJnBvb2xfdGltZW91dD0wJnNvY2tldF90aW1lb3V0PTAmc3NsbW9kZT1kaXNhYmxlIiwic2hhZG93RGF0YWJhc2VVcmwiOiJwb3N0Z3JlczovL3Bvc3RncmVzOnBvc3RncmVzQGxvY2FsaG9zdDo1MTIxNS90ZW1wbGF0ZTE_Y29ubmVjdGlvbl9saW1pdD0xJmNvbm5lY3RfdGltZW91dD0wJm1heF9pZGxlX2Nvbm5lY3Rpb25fbGlmZXRpbWU9MCZwb29sX3RpbWVvdXQ9MCZzb2NrZXRfdGltZW91dD0wJnNzbG1vZGU9ZGlzYWJsZSJ9"




Test Point 1.1: Database Connection:
Test after setting up .env
DATABASE_URL="postgresql://username:password@localhost:5432/neurokick_meetings?schema=public"

Test Point 1.2: Schema Generation:
npx prisma generate
npx prisma db push
✅ Success Indicator: No errors, tables created in TimescaleDB

Test Point 1.3: Prisma Studio:
npx prisma studio
✅ Success Indicator: Can see empty tables at localhost:5555

Go forth with Phase 2 implementation + testing: