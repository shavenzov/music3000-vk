package com.audioengine.automatization
{
	import com.audioengine.automatization.easing.IEasing;
	import com.audioengine.automatization.easing.Linear;
	
	import flash.utils.ByteArray;
	
	import mx.core.IDataRenderer;
	import mx.core.mx_internal;
	
	use namespace mx_internal;

	public class AutomatizationTrack implements IDataRenderer
	{
		private var _minValue : Number;
		private var _maxValue : Number;
		private var _defaultValue : Number;
		
		private var _data     : Object;
		
		private var _points   : Vector.<AutomatizationPoint>;
		
		private var _duration : Number;
		
		/**
		 * Счетчик идентификаторов точек (для генерации уникальных идентификаторов точек) 
		 */		
		mx_internal var id_counter : uint;
		
		public function AutomatizationTrack( data : Object = null, defaultValue : Number = 50.0, minValue : Number = 0.0, maxValue : Number = 100.0 )
		{
		  super();
			
		  _data         = data;
		  _defaultValue = defaultValue;
		  _minValue     = minValue;
		  _maxValue     = maxValue;
		  
		  _points       = new Vector.<AutomatizationPoint>();
		  interpolatorClass = Linear;
		  
		  result        = new ByteArray();
		}
        
		private function getUniqPointId() : uint
		{
			id_counter ++;
			
			return id_counter;
		}
		
		private var _interpolator      : IEasing;
		private var _interpolatorClass : Class;
		
		public function get interpolatorClass() : Class
		{
			return _interpolatorClass;
		}

		public function set interpolatorClass( value : Class ) : void
		{
			if ( _interpolatorClass != value )
			{
				_interpolatorClass = value;
				_interpolator      = new _interpolatorClass();
			}
		}

		/**
		 * Длина дорожки 
		 */
		public function get duration():Number
		{
			return _duration;
		}

		/**
		 * @private
		 */
		public function set duration(value:Number):void
		{
			_duration = value;
		}

		/**
		 * Значение по умолчанию 
		 */
		public function get defaultValue():Number
		{
			return _defaultValue;
		}

		/**
		 * @private
		 */
		public function set defaultValue(value:Number):void
		{
			_defaultValue = value;
		}

		/**
		 * Точки автоматизации 
		 */
		public function get points():Vector.<AutomatizationPoint>
		{
			return _points;
		}

		/**
		 * Данные связанные с дорожкой автоматизации 
		 */
		public function get data():Object
		{
			return _data;
		}

		/**
		 * @private
		 */
		public function set data(value:Object):void
		{
			_data = value;
		}

		/**
		 * Максимальное значение 
		 */
		public function get maxValue():Number
		{
			return _maxValue;
		}

		/**
		 * @private
		 */
		public function set maxValue(value:Number):void
		{
			_maxValue = value;
		}

		/**
		 * Минимальное значение 
		 */
		public function get minValue():Number
		{
			return _minValue;
		}

		/**
		 * @private
		 */
		public function set minValue(value:Number):void
		{
			_minValue = value;
		}
		
		public function getPointById( id : uint ) : AutomatizationPoint
		{
			var index : int = getPointIndexById( id );
			
			if ( index == -1 )
			{
				return _points[ index ];
			}
			
			return null;
		}
		
		/**
		 * Возвращает индекс точки по его идентификатору 
		 * @param id идентификатор точки
		 * @return индес точки в списке points
		 * 
		 */		
		public function getPointIndexById( id : uint ) : int
		{
			var index : int;
			
			for( index = 0; index < _points.length; index ++ )
			{
				if ( _points[ index ].id == id )
				{
					return index;
				}
			}
			
			return -1;
		}
		
		/**
		 * Добавляет новую точку 
		 * @param point новая добавляемая точка
		 * return индекс в списке точек
		 */		
		public function add( point : AutomatizationPoint ) : int
		{
			/*
			Если для точки не указан идентификатор, то указываем его
			*/
			if ( point.id == 0 )
			{
				point.setId( getUniqPointId() );
			}
			
			_points.push( point );
			
			return _points.indexOf( point );
		}
		
		/**
		 * Добавляет несколько точек в список точек за раз 
		 * @param points список точек
		 * 
		 */		
		public function addPoints( points : Vector.<AutomatizationPoint> ) : void
		{
			var point : AutomatizationPoint;
			
			for each( point in points )
			{
				/*
				Если для точки не указан идентификатор, то указываем его
				*/
				if ( point.id == 0 )
				{
					point.setId( getUniqPointId() );
				} 
			}
			
			_points = _points.concat( points );
		}
		
		/**
		 * Удаляет точку из списка 
		 * @param point точка которую необходимо удалить
		 * @return индекс где находилась точка или -1, если такой точки не найдено
		 * 
		 */		
		public function remove( point : AutomatizationPoint ) : int
		{
			var index : int = _points.indexOf( point );
			
			if ( index > -1 )
			{
				_points.splice( index, 1 );
			}
			
			return index;
		}
		
		/**
		 * Удаляет точку из списка по её идентификатору 
		 * @param id идентификатор точки
		 * @return индекс удаленной точки или -1, если такой точки не найдено
		 * 
		 */		
		public function removePointById( id : uint ) : int
		{
			var index : int = getPointIndexById( id );
			
			if ( index != -1 )
			{
				_points.splice( index, 1 );
			}
			
			return index;
		}
		
		/**
		 * Удаляет сразу несколько точек из списка по их идентификатору 
		 * @param ids список идентификаторов точек для удаления
		 * 
		 */		
		public function removePointsById( ids : Vector.<uint> ) : void
		{
			var id    : uint;
			
			for each( id in ids )
			{
				removePointById( id ); 
			}
		}
		
		/**
		 * Удаляет все точки автоматизации 
		 * 
		 */		
		public function clear() : void
		{
			_points = new Vector.<AutomatizationPoint>();
		}
		
		/**
		 * Возвращает все точки на заданном интервале 
		 * @param from начало интервала
		 * @param to конец интервала
		 * @return список точек на интервале
		 * 
		 */		
		public function getPoints( from : Number, to : Number ) : Vector.<AutomatizationPoint>
		{
			var i        : int;
			var result   : Vector.<AutomatizationPoint> = new Vector.<AutomatizationPoint>();
			var point    : AutomatizationPoint;
			
			var startPoint : AutomatizationPoint = new AutomatizationPoint( 0.0, _defaultValue );
			var endPoint   : AutomatizationPoint = new AutomatizationPoint( _duration - 1, _defaultValue );
			
			for ( i = 0; i < _points.length; i ++ )
			{
				point = _points[ i ];
				
				//Находим первую точку вне интервала
				if ( point.position <= from )
				{
					if ( startPoint.position <= point.position )
					{
						startPoint = point;
					}
				}
				else
				//Находим точки на интервале
				if ( ( point.position > from ) && ( point.position < to ) )
				{
					result.push( point );
				}
				else
				//Находим первую точку после интервала
				if ( point.position >= to )
				{
					if ( point.position <= endPoint.position )
					{
						endPoint = point;
					}
				}
			}
			
			if ( result.length > 0 )
			{
				if ( result[ 0 ].position != startPoint.position )
				{
					result.unshift( startPoint );
				}
				
				if ( result[ result.length - 1 ].position != endPoint.position )
				{
					result.push( endPoint );
				}
			}
			else
			{
				result.push( startPoint );
				result.push( endPoint );
			}
			
			
			return result;
		}
		
		public function copy( from : Number, to : Number ) : ByteArray
		{
			var points : Vector.<AutomatizationPoint> = getPoints( from, to );
			var length : Number = to - from;
			
			var data   : ByteArray = new ByteArray();
			    /*data.length = length * 4.0;
				data.position = 0;*/
			
			var i         : int;
			var cFrom     : Number;
			var cTo       : Number;
			var point1    : AutomatizationPoint;
			var point2    : AutomatizationPoint;
			var lastIndex : int = points.length - 2;
			
			for ( i = 0; i < points.length - 1; i ++ )
			{
				point1 = points[ i ];
				point2 = points[ i + 1 ];
				
				cFrom = Math.max( point1.position, from );
				cTo   = Math.min( point2.position, to );
				
				if ( i < lastIndex )
				{
					cTo --;
				}
				
				fill( data, point1, point2, cFrom, cTo );
			}
			
			return data;
		}
		
		/*
		private function _fill( data : ByteArray, point1 : AutomatizationPoint, point2 : AutomatizationPoint, from : Number, to : Number ) : void
		{
			var duration : Number = point2.position - point1.position;
			var dValue   : Number = point2.value - point1.value; 
			var fromPos  : Number = from - point1.position;
			var toPos    : Number = to   - point1.position;
			
			var i      : int;
			var value  : Number;
			
			for ( i = fromPos; i <= toPos; i ++ )
			{
				
				
				value = calculate( i, point1.value, dValue, duration );
				
				data.writeFloat( value );
			}
		}
		
		public function calculate(t:Number, b:Number, c:Number, d:Number):Number
		{
			return ((c * t) / d ) + b;
		}
		*/
		
		private var result : ByteArray;
		
		private function fill( data : ByteArray, point1 : AutomatizationPoint, point2 : AutomatizationPoint, from : Number, to : Number ) : void
		{
			var d        : Number = point2.position - point1.position;
			var c        : Number = point2.value - point1.value; 
			var fromPos  : Number = from - point1.position;
			var toPos    : Number = to   - point1.position;
			var duration : Number = ( toPos - fromPos ) + 1.0;
			
			_interpolator.length = duration;
			
			result.length = duration  * 4;
			result.position = 0;
			
			trace();
			trace( 'from', fromPos );
			trace();
			
			_interpolator.t = fromPos;
			_interpolator.b = point1.value;
			_interpolator.c = c;
			_interpolator.d = d;
			
			_interpolator.calculate( result );
			
			data.writeBytes( result ); 
		}
		
		public function update() : void
		{
			sortPoints();
		}
		
		/**
		 * Сортирует точки в массиве _points, по возрастанию 
		 * 
		 */		
		private function sortPoints() : void
		{
		  _points.sort( sortPointsFunction );
		}
		
		private function sortPointsFunction( a : AutomatizationPoint, b : AutomatizationPoint ) : Number
		{
			if( a.position > b.position ) {
				return 1;
			} else if ( a.position < b.position ) {
				return -1;
			} 
			
			//a == b
			return 0;
		}
		
		public function clone() : AutomatizationTrack
		{
			var at : AutomatizationTrack = new AutomatizationTrack( _data, _defaultValue, _minValue, _maxValue );
			    at.id_counter = id_counter;
				at.duration   = _duration;
				at.interpolatorClass = _interpolatorClass;
				
			var clonnedPoints : Vector.<AutomatizationPoint> = new Vector.<AutomatizationPoint>( _points.length );
			
			for ( var i : int = 0; i < _points.length; i ++ )
			{
				clonnedPoints[ i ] = _points[ i ].clone();
			}
			
			at.addPoints( clonnedPoints );   
			
			return at;
		}

	}
}