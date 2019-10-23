package com.audioengine.core
{
	import com.audioengine.sources.Routines;

	public final class TimeConversion
	{
		/**
		 * Количество ударов в одном такте 
		 */		
		public static const NUM_BARS : Number = 4.0; // 1/4
		
		/**
		 * Размер удара в долях 
		 */		
		public static const BIT_DURATION : Number = 1 / NUM_BARS;
		
		/**
		 * Ударов в одном такте по умолчанию * 60 секунд ( Длительность тактов 1/2, 1/3, 1/4 )
		 */		
		public static const BAR_DURATION_FACTOR : Number = NUM_BARS * 60.0; // 1/4 * 60
		
		public static function barsToMillis( bars:Number, bpm: Number ):Number
		{
			return ( bars * BAR_DURATION_FACTOR / bpm ) * 1000.0;
		}
		
		public static function barsToSecs( bars:Number, bpm: Number ):Number
		{
			return ( bars * BAR_DURATION_FACTOR / bpm );
		}
		
		public static function barsToNumSamples( bars:Number, bpm: Number ):Number
		{
			return ( bars * BAR_DURATION_FACTOR / bpm ) * AudioData.RATE;
		}
		
		public static function bitsToNumSamples( numBits : Number, bpm : Number ) : Number
		{
			return ( ( 60.0 * numBits ) / bpm ) * AudioData.RATE;
		}
		
		public static function numSamplesToBits( numSamples : Number, bpm : Number ) : Number
		{
			return ( ( numSamples  / AudioData.RATE ) / 60.0 ) * bpm;
		}
		
		public static function bitsToSeconds( numBits : Number, bpm : Number ) : Number
		{
			return ( 60.0 * numBits ) / bpm;
		}	
		
		public static function millisToBars( millis:Number, bpm: Number ):Number
		{
			return ( millis * bpm / BAR_DURATION_FACTOR ) / 1000.0;
		}
		
		public static function secsToBars( millis:Number, bpm: Number ):Number
		{
			return ( millis * bpm / BAR_DURATION_FACTOR );
		}
		
		public static function numSamplesToBars( numSamples: Number, bpm: Number ):Number
		{
			return ( numSamples * bpm / BAR_DURATION_FACTOR ) / AudioData.RATE;
		}
		
		public static function numSamplesToSeconds( numSamples : int ) : Number
		{
			return numSamples / AudioData.RATE;
		}
		
		public static function numSamplesToMiliseconds( numSamples : int ) : Number
		{
			return ( numSamples / AudioData.RATE ) * 1000.0;
		}
		
		public static function secondsToNumSamples( seconds : Number ) : Number
		{
			return  seconds * AudioData.RATE;
		}
		
		public static function milisecondToNumSamples( miliseconds : Number ) : Number
		{
			return ( miliseconds * AudioData.RATE ) / 1000.0;
		}	
		
		public static function scaleDuration( duration : Number, srcBPM : Number, dstBPM : Number ) : Number
		{
			return duration * ( srcBPM / dstBPM );
		}
		
		public static function scaleFactor( srcBPM : Number, dstBPM : Number ) : Number
		{
			return srcBPM / dstBPM;
		}
		
		public static function calcLoopDuration( duration : Number, srcBPM : Number, dstBPM : Number ) : Number
		{
			return scaleDuration( Routines.floorLength(  Routines.ceilLength( duration, srcBPM ), srcBPM ), srcBPM, dstBPM );
		}
		
		public static function ceilNumSamplesToWholeBar( numSamples : Number, bpm : Number ) : Number
		{
			return barsToNumSamples( Math.ceil(numSamplesToBars( numSamples, bpm ) ), bpm );
		}
		
		public static function roundNumSamplesToWholeBar( numSamples : Number, bpm : Number ) : Number
		{
			return barsToNumSamples( Math.round(numSamplesToBars( numSamples, bpm ) ), bpm );
		}
	}
}