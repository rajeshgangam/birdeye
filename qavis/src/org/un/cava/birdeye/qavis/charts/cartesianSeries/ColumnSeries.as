/*  
 * The MIT License
 *
 * Copyright (c) 2008
 * United Nations Office at Geneva
 * Center for Advanced Visual Analytics
 * http://cava.unog.ch
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */
 
package org.un.cava.birdeye.qavis.charts.cartesianSeries
{
	import com.degrafa.IGeometry;
	import com.degrafa.geometry.Line;
	import com.degrafa.geometry.RegularRectangle;
	import com.degrafa.paint.SolidFill;
	import com.degrafa.paint.SolidStroke;
	
	import mx.collections.CursorBookmark;
	
	import org.un.cava.birdeye.qavis.charts.axis.NumericAxisUI;
	import org.un.cava.birdeye.qavis.charts.axis.XYZAxisUI;
	import org.un.cava.birdeye.qavis.charts.cartesianCharts.ColumnChart;
	import org.un.cava.birdeye.qavis.charts.renderers.RectangleRenderer;

	public class ColumnSeries extends StackableSeries 
	{
		override public function get seriesType():String
		{
			return "column";
		}

		private var _baseAtZero:Boolean = true;
		[Inspectable(enumeration="true,false")]
		public function set baseAtZero(val:Boolean):void
		{
			_baseAtZero = val;
			invalidateProperties();
			invalidateDisplayList();
		}
		public function get baseAtZero():Boolean
		{
			return _baseAtZero;
		}
		
		private var _form:String;
		public function set form(val:String):void
		{
			_form = val;
			invalidateDisplayList();
		}

		public function ColumnSeries()
		{
			super();
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			if (!itemRenderer)
				itemRenderer = RectangleRenderer;

			if (stackType == STACKED100)
			{
				if (yAxis)
				{
					if (yAxis is NumericAxisUI)
						NumericAxisUI(yAxis).max = maxYValue;
				} else {
					if (chart && chart.yAxis && chart.yAxis is NumericAxisUI)
						NumericAxisUI(chart.yAxis).max = maxYValue;
				}
			}
		}

		private var poly:IGeometry;
		/** @Private 
		 * Called by super.updateDisplayList when the series is ready for layout.*/
		override protected function drawSeries():void
		{
			var dataFields:Array = [];

			var xPos:Number, yPos:Number, zPos:Number;
			var j:Number = 0;
			
			var ttShapes:Array;
			var ttXoffset:Number = NaN, ttYoffset:Number = NaN;
			
			var y0:Number = getYMinPosition();
			var size:Number = NaN, colWidth:Number = 0; 

			cursor.seek(CursorBookmark.FIRST);

			while (!cursor.afterLast)
			{
				if (xAxis)
				{
					xPos = xAxis.getPosition(cursor.current[xField]);

					dataFields[0] = xField;

					if (isNaN(size))
						size = xAxis.interval*deltaSize;
				} else {
					xPos = chart.xAxis.getPosition(cursor.current[xField]);

					dataFields[0] = xField;

					if (isNaN(size))
						size = chart.xAxis.interval*deltaSize;
				}
				
				if (yAxis)
				{
					if (_stackType == STACKED100)
					{
						y0 = yAxis.getPosition(baseValues[j]);
						yPos = yAxis.getPosition(
							baseValues[j++] + Math.max(0,cursor.current[yField]));
					} else {
						yPos = yAxis.getPosition(cursor.current[yField]);
					}
					dataFields[1] = yField;
				}
				else {
					if (_stackType == STACKED100)
					{
						y0 = chart.yAxis.getPosition(baseValues[j]);
						yPos = chart.yAxis.getPosition(
							baseValues[j++] + Math.max(0,cursor.current[yField]));
					} else 
						yPos = chart.yAxis.getPosition(cursor.current[yField]);

					dataFields[1] = yField;
				}
				
				switch (_stackType)
				{
					case OVERLAID:
						colWidth = size;
						xPos = xPos - size/2;
						break;
					case STACKED100:
						colWidth = size;
						xPos = xPos - size/2;
						ttShapes = [];
						ttXoffset = -30;
						ttYoffset = 20;
						var line:Line = new Line(xPos+ colWidth/2, yPos, xPos + colWidth/2 + ttXoffset/3, yPos + ttYoffset);
						line.stroke = new SolidStroke(0xaaaaaa,1,2);
		 				ttShapes[0] = line;
						break;
					case STACKED:
						xPos = xPos + size/2 - size/_total * _stackPosition;
						colWidth = size/_total;
						break;
				}
				
				var yAxisRelativeValue:Number = NaN;

				if (zAxis)
				{
					zPos = zAxis.getPosition(cursor.current[zField]);
					yAxisRelativeValue = XYZAxisUI(zAxis).height - zPos;
					dataFields[2] = zField;
				} else if (chart.zAxis) {
					zPos = chart.zAxis.getPosition(cursor.current[zField]);
					// since there is no method yet to draw a real z axis 
					// we create an y axis and rotate it to properly visualize 
					// a 'fake' z axis. however zPos over this y axis corresponds to 
					// the axis height - zPos, because the y axis in Flex is 
					// up side down. this trick allows to visualize the y axis as
					// if it would be a z. when there will be a 3d line class, it will 
					// be replaced
					yAxisRelativeValue = XYZAxisUI(chart.zAxis).height - zPos;
					dataFields[2] = zField;
				}

 				var bounds:RegularRectangle = new RegularRectangle(xPos, yPos, colWidth, y0 - yPos);

				if (chart.showDataTips)
				{	// yAxisRelativeValue is sent instead of zPos, so that the axis pointer is properly
					// positioned in the 'fake' z axis, which corresponds to a real y axis rotated by 90 degrees
					createGG(cursor.current, dataFields, xPos + colWidth/2, yPos, yAxisRelativeValue, 3,ttShapes,ttXoffset,ttYoffset);
					var hitMouseArea:IGeometry = new itemRenderer(bounds); 
					hitMouseArea.fill = new SolidFill(0x000000, 0);
					gg.geometryCollection.addItem(hitMouseArea);
				}

				poly = new itemRenderer(bounds);

				poly.fill = fill;
				poly.stroke = stroke;
				gg.geometryCollection.addItemAt(poly,0);
				if (zField)
				{
					gg.z = zPos;
					if (isNaN(zPos))
						zPos = 0;
				}
				cursor.moveNext();
			}

			if (zField)
				zSort();
		}
		
/* 		private function getXMinPosition():Number
		{
			var xPos:Number;
			
			if (xAxis)
			{
				if (xAxis is NumericAxis)
					xPos = xAxis.getPosition(minXValue);
			} else {
				if (chart.xAxis is NumericAxis)
					xPos = chart.xAxis.getPosition(minXValue);
			}
			
			return xPos;
		}
 */		
		private function getYMinPosition():Number
		{
			var yPos:Number;
			if (yAxis && yAxis is NumericAxisUI)
			{
				if (_baseAtZero)
					yPos = yAxis.getPosition(0);
				else
					yPos = yAxis.getPosition(NumericAxisUI(yAxis).min);
			} else {
				if (chart.yAxis is NumericAxisUI)
				{
					if (_baseAtZero)
						yPos = chart.yAxis.getPosition(0);
					else
						yPos = chart.yAxis.getPosition(NumericAxisUI(chart.yAxis).min);
				}
			}
			return yPos;
		}
		
		override protected function calculateMaxY():void
		{
			super.calculateMaxY();
			if (chart && chart is ColumnChart && stackType == STACKED100)
				_maxYValue = Math.max(_maxYValue, ColumnChart(chart).maxStacked100);
		}
	}
}