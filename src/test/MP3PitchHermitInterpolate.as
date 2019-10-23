package test 
{
	import com.audioengine.utils.SoundUtils;
	
	import flash.events.Event;
	import flash.events.SampleDataEvent;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	
	/**
	 * @author Andre Michelle (andre.michelle@gmail.com)
	 */
	public class MP3PitchHermitInterpolate 
	{
		private const BLOCK_SIZE: int = 3072;
		
		private var _mp3: Sound;
		private var _sound: Sound;
		private var _ch : SoundChannel;
		
		private var _target: ByteArray;
		
		private var _position: Number;
		private var _rate: Number;
		
		public function MP3PitchHermitInterpolate( url: String )
		{
			_target = new ByteArray();
			
			_mp3 = new Sound();
			_mp3.load( new URLRequest( url ) );
			_mp3.addEventListener( Event.COMPLETE, complete );
			
			_position = 64100;
			_rate = 0.9;
			
			_sound = new Sound();
			_sound.addEventListener( SampleDataEvent.SAMPLE_DATA, sampleData );
		}
		
		public function get rate(): Number
		{
			return _rate;
		}
		
		public function set rate( value: Number ): void
		{
			if( value < 0.0 )
				value = 0;
			
			_rate = value;
		}
		
		private function complete( event: Event ): void
		{
			
		}
		
		public function start() : void
		{
			_ch = _sound.play();
		}
		
		public function stop() : void
		{
			_ch.stop();
			_ch = null;
		}	
		
		private static function HermiteInterpolate(y0:Number,y1:Number,y2:Number,y3:Number,mu:Number,tension:Number = 0,bias:Number = 0):Number {
			/* Tension: 1 is high, 0 normal, -1 is low
			Bias: 0 is even, positive is towards first segment, negative towards the other */
			var mu2:Number = mu * mu;
			var mu3:Number = mu2 * mu;
			var m0:Number  = (y1-y0)*(1+bias)*(1-tension)/2;
			m0 += (y2-y1)*(1-bias)*(1-tension)/2;
			var m1:Number  = (y2-y1)*(1+bias)*(1-tension)/2;
			m1 += (y3-y2)*(1-bias)*(1-tension)/2;
			var a0:Number =  2*mu3 - 3*mu2 + 1;
			var a1:Number =    mu3 - 2*mu2 + mu;
			var a2:Number =    mu3 -   mu2;
			var a3:Number = -2*mu3 + 3*mu2;
			
			return (a0*y1+a1*m0+a2*m1+a3*y2);
		}
		
		private static function lowpass(prev:Number, value:Number, alpha : Number ):Number { // Return RC low-pass filter			
			//see Algorithmic implementation in
			//http://en.wikipedia.org/wiki/Low-pass_filter 
			//var alpha:Number = dt / (rc + dt);
			return alpha * value + ( 1 - alpha ) * prev;
		}
		
		private function sampleData( event: SampleDataEvent ): void
		{
			//-- REUSE INSTEAD OF RECREATION
			_target.position = 0;
			
			//-- SHORTCUT
			var data: ByteArray = event.data;
			
			var scaledBlockSize: Number = BLOCK_SIZE * _rate;
			var positionInt: int = _position;
			var alpha: Number = _position - positionInt;
			
			var positionTargetNum: Number = alpha;
			var positionTargetInt: int = -1;
			
			//-- COMPUTE NUMBER OF SAMPLES NEED TO PROCESS BLOCK (+2 FOR INTERPOLATION)
			var need: int = Math.ceil( scaledBlockSize ) + 4;
			
			//-- EXTRACT SAMPLES
			var read: int = _mp3.extract( _target, need, positionInt );
			
			var n: int = read == need ? BLOCK_SIZE : read / _rate;
			
			var l0: Number;
			var r0: Number;
			var l1: Number;
			var r1: Number;
			var l2: Number;
			var r2: Number;
			var l3: Number;
			var r3: Number;
			var lastL : Number = 0.0;
			var lastR : Number = 0.0;
			
			for( var i: int = 0 ; i < n ; ++i )
			{
				//-- AVOID READING EQUAL SAMPLES, IF RATE < 1.0
				if( int( positionTargetNum ) != positionTargetInt )
				{
					positionTargetInt = positionTargetNum;
					
					//-- SET TARGET READ POSITION
					_target.position = positionTargetInt << 3;
					
					//-- READ TWO STEREO SAMPLES FOR LINEAR INTERPOLATION
					l0 = _target.readFloat();
					r0 = _target.readFloat();
					
					l1 = _target.readFloat();
					r1 = _target.readFloat();
					
					l2 = _target.readFloat();
					r2 = _target.readFloat();
					
					l3 = _target.readFloat();
					r3 = _target.readFloat();
				}
				
				//-- WRITE INTERPOLATED AMPLITUDES INTO STREAM
				 l0 = HermiteInterpolate( l0, l1, l2, l3, alpha );
				 r0 = HermiteInterpolate( r0, r1, r2, r3, alpha );
				 
				 				 
				 data.writeFloat( l0 );
				 data.writeFloat( r0 );
				
				//-- INCREASE TARGET POSITION
				positionTargetNum += _rate;
				
				//-- INCREASE FRACTION AND CLAMP BETWEEN 0 AND 1
				/*alpha += _rate;
				while( alpha >= 1.0 ) --alpha;*/
			}
			
			//-- FILL REST OF STREAM WITH ZEROs
			if( i < BLOCK_SIZE )
			{
				while( i < BLOCK_SIZE )
				{
					data.writeFloat( 0.0 );
					data.writeFloat( 0.0 );
					
					++i;
				}
				
				_position = 0.0;
			}
			else
			//-- INCREASE SOUND POSITION
			_position += scaledBlockSize;
		}
	}
}