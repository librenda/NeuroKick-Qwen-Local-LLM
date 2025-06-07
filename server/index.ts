import express from 'express';
import { PrismaClient } from '@prisma/client';
import cors from 'cors';

const app = express();
const prisma = new PrismaClient();

// Middleware
app.use(express.json({ limit: '50mb' })); // Increased limit for large transcripts
app.use(cors({
  origin: ['http://localhost:3000', 'http://127.0.0.1:3000'],
  credentials: true
}));

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    timestamp: new Date().toISOString(),
    database: 'connected'
  });
});

// Create meeting
app.post('/api/meetings', async (req, res) => {
  try {
    const { audioPath, duration } = req.body;
    
    const meeting = await prisma.meeting.create({
      data: {
        audioPath,
        duration,
        status: 'recording'
      }
    });
    
    res.json(meeting);
  } catch (error) {
    console.error('Error creating meeting:', error);
    res.status(500).json({ error: 'Failed to create meeting' });
  }
});

// Update meeting status
app.patch('/api/meetings/:id/status', async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;
    
    await prisma.meeting.update({
      where: { id },
      data: { status }
    });
    
    res.json({ success: true });
  } catch (error) {
    console.error('Error updating meeting status:', error);
    res.status(500).json({ error: 'Failed to update meeting status' });
  }
});

// NEW: Store transcription
app.post('/api/meetings/:id/transcription', async (req, res) => {
  try {
    const { id } = req.params;
    const { text, confidence } = req.body;
    
    const transcription = await prisma.transcription.upsert({
      where: { meetingId: id },
      create: {
        meetingId: id,
        text,
        confidence
      },
      update: {
        text,
        confidence,
        timestamp: new Date()
      }
    });
    
    res.json(transcription);
  } catch (error) {
    console.error('Error storing transcription:', error);
    res.status(500).json({ error: 'Failed to store transcription' });
  }
});

// NEW: Store behavioral analysis
app.post('/api/meetings/:id/behavioral-analysis', async (req, res) => {
  try {
    const { id } = req.params;
    const { 
      managerName, 
      multiplierCount, 
      diminisherCount, 
      accidentalDiminisherCount,
      analysisData,
      trainingRecommendations,
      keyInsights,
      behaviors 
    } = req.body;
    
    // Store the main behavioral analysis
    const behaviorAnalysis = await prisma.behaviorAnalysis.upsert({
      where: { meetingId: id },
      create: {
        meetingId: id,
        managerName,
        multiplierCount: multiplierCount || 0,
        diminisherCount: diminisherCount || 0,
        accidentalDiminisherCount: accidentalDiminisherCount || 0,
        analysisData,
        trainingRecommendations,
        keyInsights
      },
      update: {
        managerName,
        multiplierCount: multiplierCount || 0,
        diminisherCount: diminisherCount || 0,
        accidentalDiminisherCount: accidentalDiminisherCount || 0,
        analysisData,
        trainingRecommendations,
        keyInsights,
        timestamp: new Date()
      }
    });
    
    // Store individual behavior instances if provided
    if (behaviors && Array.isArray(behaviors)) {
      // Delete existing behavior instances
      await prisma.behaviorInstance.deleteMany({
        where: { behaviorAnalysisId: behaviorAnalysis.id }
      });
      
      // Create new behavior instances
      await prisma.behaviorInstance.createMany({
        data: behaviors.map((behavior: any) => ({
          behaviorAnalysisId: behaviorAnalysis.id,
          context: behavior.context,
          quote: behavior.quote,
          behaviorType: behavior.behaviorType,
          specificBehavior: behavior.specificBehavior,
          implications: behavior.implications
        }))
      });
    }
    
    // Return the analysis with behavior instances
    const completeAnalysis = await prisma.behaviorAnalysis.findUnique({
      where: { id: behaviorAnalysis.id },
      include: {
        behaviors: true
      }
    });
    
    res.json(completeAnalysis);
  } catch (error) {
    console.error('Error storing behavioral analysis:', error);
    res.status(500).json({ error: 'Failed to store behavioral analysis' });
  }
});

// NEW: Store summary
app.post('/api/meetings/:id/summary', async (req, res) => {
  try {
    const { id } = req.params;
    const { content } = req.body;
    
    const summary = await prisma.summary.upsert({
      where: { meetingId: id },
      create: {
        meetingId: id,
        content
      },
      update: {
        content,
        timestamp: new Date()
      }
    });
    
    res.json(summary);
  } catch (error) {
    console.error('Error storing summary:', error);
    res.status(500).json({ error: 'Failed to store summary' });
  }
});

// NEW: Get M/D/AD behavior trends
app.get('/api/analytics/behavior-trends', async (req, res) => {
  try {
    const days = parseInt(req.query.days as string) || 30;
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);
    
    const behaviorTrends = await prisma.behaviorAnalysis.findMany({
      where: {
        timestamp: {
          gte: startDate
        }
      },
      include: {
        meeting: {
          select: {
            timestamp: true,
            duration: true
          }
        },
        behaviors: {
          select: {
            behaviorType: true,
            specificBehavior: true,
            context: true
          }
        }
      },
      orderBy: {
        timestamp: 'desc'
      }
    });
    
    // Aggregate data for visualization
    const aggregatedData = behaviorTrends.map(analysis => ({
      date: analysis.timestamp.toISOString().split('T')[0],
      meetingId: analysis.meetingId,
      managerName: analysis.managerName,
      multipliers: analysis.multiplierCount,
      diminishers: analysis.diminisherCount,
      accidentalDiminishers: analysis.accidentalDiminisherCount,
      totalBehaviors: analysis.multiplierCount + analysis.diminisherCount + analysis.accidentalDiminisherCount,
      netScore: analysis.multiplierCount - analysis.diminisherCount, // Positive = more multiplying
      behaviors: analysis.behaviors
    }));
    
    res.json(aggregatedData);
  } catch (error) {
    console.error('Error getting behavior trends:', error);
    res.status(500).json({ error: 'Failed to get behavior trends' });
  }
});

// Get meeting trends (optimized for time series)
app.get('/api/analytics/trends', async (req, res) => {
  try {
    const days = parseInt(req.query.days as string) || 30;
    
    // For now, using basic Prisma query - can optimize with raw SQL later
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);
    
    const metrics = await prisma.meetingMetric.groupBy({
      by: ['timestamp'],
      where: {
        timestamp: {
          gte: startDate
        }
      },
      _avg: {
        sentiment: true
      },
      _count: {
        meetingId: true
      }
    });
    
    const trends = metrics.map((metric: any) => ({
      date: metric.timestamp.toISOString().split('T')[0],
      averageSentiment: metric._avg.sentiment || 0,
      meetingCount: metric._count.meetingId || 0,
      topTopics: [] // TODO: Implement topic analysis
    }));
    
    res.json(trends);
  } catch (error) {
    console.error('Error getting trends:', error);
    res.status(500).json({ error: 'Failed to get trends' });
  }
});

// Get all meetings with enhanced data
app.get('/api/meetings', async (req, res) => {
  try {
    const meetings = await prisma.meeting.findMany({
      include: {
        transcription: true,
        analysis: true,
        summary: true,
        behaviorAnalysis: {
          include: {
            behaviors: true
          }
        },
        _count: {
          select: {
            metrics: true
          }
        }
      },
      orderBy: {
        timestamp: 'desc'
      }
    });
    
    res.json(meetings);
  } catch (error) {
    console.error('Error getting meetings:', error);
    res.status(500).json({ error: 'Failed to get meetings' });
  }
});

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`🚀 Meeting Analytics API running on port ${PORT}`);
  console.log(`📊 Health check: http://localhost:${PORT}/api/health`);
  console.log(`🧠 Behavioral analysis endpoints available`);
}); 