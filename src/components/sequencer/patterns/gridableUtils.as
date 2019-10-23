/**
 * Возвращает оптимальный шаг сетки, в зависимости от минимального интервала между клетками
 *  
 * @param _interval - интервал в масштабе 1:1
 * @param _minStep  - минимальное расстояние между ячейками
 * @return оптимальное значение шага между ячейками
 * 
 */		
public function getOptimizedStep( _interval : Number, _minStep : Number ) : Number
{
	var step : Number = 0;
	var inc  : Number = 1;
	
	while( step < _minStep )
	{
		step = ( _interval * inc ) / _scale;
		inc ++;
	}
	
	return step;
}

/**
 * Возвращает кол-во линий сетки которые можно нарисовать с указанным шагом 
 * @param step шаг сетки
 * @return кол-во линий сетки которые можно нарисовать
 * 
 */		
public function getGridLinesCount( step : Number ) : Number
{
	return Math.ceil( ( ( _duration )  / step ) / _scale );
}	