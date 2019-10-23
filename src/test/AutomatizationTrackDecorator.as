package test
{
	import com.audioengine.automatization.AutomatizationPoint;
	import com.audioengine.automatization.AutomatizationTrack;
	
	import mx.core.mx_internal;
	
	use namespace mx_internal;

	public class AutomatizationTrackDecorator 
	{
		private var _scale : Number;
		
		private var _original : AutomatizationTrack;
		private var _scaled   : AutomatizationTrack;
		
		public function AutomatizationTrackDecorator( original : AutomatizationTrack)
		{
		  super();
		  
		  _original = original;
		}

		public function get original():AutomatizationTrack
		{
			return _original;
		}

		public function get scaled():AutomatizationTrack
		{
			return _scaled;
		}

		public function get scale():Number
		{
			return _scale;
		}

		public function set scale(value:Number):void
		{
			if ( scale != value )
			{
				_scale = value;
				syncOriginalAndScaled();
			}
		}
		
		/**
		 * Синхронизирует оригинальную дорожку с масштабированной
		 * 
		 */		
		private function syncOriginalAndScaled() : void
		{
		  _scaled = _original.clone();
		  _scaled.duration /= _scale;
		  
		  var point : AutomatizationPoint
		  
		  for each( point in _scaled.points )
		  {
			  point.position /= _scale;
		  }
		}
		
		/**
		 * Синхронизирует масштабированную дорожку с оригинальной 
		 * 
		 */		
		private function syncScaledAndOriginal() : void
		{
			_original.duration = _scaled.duration * _scale;
			
			var scaledPoint   : AutomatizationPoint;
			var originalPoint : AutomatizationPoint;
			var originalPos   : Number;
			var addedPoints   : Vector.<AutomatizationPoint>;
			var removedPoints : Vector.<uint>;
			
			/*
			Синхронизируем положение, находим точки которые были добавлены
			*/
			for each( scaledPoint in _scaled.points )
			{
				originalPos   = scaledPoint.position * _scale;
				originalPoint = _original.getPointById( scaledPoint.id );
				
				//Точка существует. Синхронизируем положение
				if ( originalPoint )
				{
					originalPoint.position = originalPos;
				}
				else //Точка не существует. Добавляем её
				{
					if ( ! addedPoints )
					{
						addedPoints = new Vector.<AutomatizationPoint>();
					}
					
					originalPoint = new AutomatizationPoint( originalPos, scaledPoint.value );
					originalPoint.setId( scaledPoint.id );
					
					addedPoints.push( originalPoint );
				}
			}
			
			/*
			Находим точки которые были удалены
			*/
			for each( originalPoint in _original.points )
			{
				scaledPoint = _scaled.getPointById( originalPoint.id );
				
				if ( ! scaledPoint )
				{
					if ( ! removedPoints )
					{
						removedPoints = new Vector.<uint>();
					}
					
					removedPoints.push( scaledPoint.id );
				}
			}
			
			//Добавляем
			if ( addedPoints )
			{
				_original.addPoints( addedPoints );
			}
			
			//Удаляем
			if ( removedPoints )
			{
				_original.removePointsById( removedPoints );
			}
			
			_original.update();
		}
		
		/**
		 * Применяет изменения 
		 * 
		 */		
		public function commit() : void
		{
			syncScaledAndOriginal();
		}
	}
}