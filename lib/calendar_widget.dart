library calendar_widget;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';

typedef CalendarHighlighter = List<bool> Function(DateTime dt);
typedef TapListener = void Function(DateTime dt);

final double _iconButtonSize = 24.0; // default size of the arrow icon buttons

final double _marginFactor = .2; // margin is AT LEAST this times the item size
final double _maxRows = 6; // the most rows the calendar will have is 6

final double _luminanceThreshold = 0.17912878;

final int _maxPage = 9007199300000; // page number to set initial page to if enable future

class Calendar extends StatefulWidget {
  final _Values vals;

  // TODO: deal with height
  Calendar(
      {highlighter, @required width, height, onTapListener, highlightColor, enableFuture})
      : vals =
  _Values(highlighter, width, height, onTapListener, highlightColor, enableFuture);

  static int monthLength(DateTime dt) {
    int nextMonth = dt.month + 1;
    int year = dt.year;
    if (nextMonth > 12) {
      nextMonth %= 12;
      year++;
    }
    final dt2 = DateTime(
        year, nextMonth, 0); // returns datetime on last day of the month
    return dt2.day;
  }

  // helper functions
  static double _headlineTextSize(BuildContext context) {
    double fontSize = Theme.of(context).textTheme.headline.fontSize;
    double textScaleFactor = MediaQuery.textScaleFactorOf(context);
    return fontSize * textScaleFactor;
  }

  static double _defaultTextSize(BuildContext context) {
    double fontSize = Theme.of(context).textTheme.body1.fontSize;
    double textScaleFactor = MediaQuery.textScaleFactorOf(context);
    return fontSize * textScaleFactor;
  }

  static double _calculateItemSize(
      double height, double width, BuildContext context) {
    double effectiveHeight = height -
        max(_iconButtonSize, _headlineTextSize(context)) -
        _defaultTextSize(context); // effective height is height - 1st 2 rows
    // factor to multiply item size by to account for padding
    double sizeFactor = 1 - _marginFactor / (1 + _marginFactor);
    // calculate what it would be if based on height
    double hItemSize = effectiveHeight / _maxRows * sizeFactor;
    // calculate wht it would be if based on width
    double wItemSize = width / 7 * sizeFactor;

    return min(hItemSize, wItemSize); // don't want item size to be too big
  }

  // helper functions to determine whether to use white or black text
  static bool shouldUseWhiteText(Color c) {
    return c.computeLuminance() <= _luminanceThreshold;
  }

  @override
  State<Calendar> createState() {
    // default highlighter
    if (vals.highlighter == null) {
      vals.highlighter = (dt) {
        return List<bool>.filled(monthLength(dt) + 1, false);
      };
    }

    return _CalendarState(vals);
  }
}

class _Values {
  CalendarHighlighter highlighter; // function to decide which days to highlight
  final double width;
  double height;

  final TapListener onTapListener;

  double itemSize;

  PageController controller;

  Color highlightColor;
  bool whiteText;

  final enableFuture; // whether or not to allow access to future months

  _Values(
      [this.highlighter,
        this.width,
        this.height,
        this.onTapListener,
        this.highlightColor,
        this.enableFuture = false]);
}

class _CalendarState extends State<Calendar> {
  final _currentDate = DateTime.now(); // current date to determine start

  final _Values vals; // not final because must set if null value provided

  _CalendarState(this.vals);

  @override
  Widget build(BuildContext context) {
    // allow for future months by setting initial page absurdly high
    int _initialPage = 0;
    if (vals.enableFuture != null && vals.enableFuture) {
      _initialPage = _maxPage;
    }

    vals.controller = new PageController(initialPage: _initialPage); // controller for the PageView
    // default height
    if (vals.height == null) {
      vals.height = max(_iconButtonSize, Calendar._headlineTextSize(context)) +
          Calendar._defaultTextSize(context) +
          vals.width;
    }
    // calculate what each day's item size should be
    vals.itemSize =
        Calendar._calculateItemSize(vals.height, vals.width, context);

    // default highlight color and also determine whether to use white or black text
    if (vals.highlightColor == null) {
      vals.highlightColor = Theme.of(context).accentColor;
    }
    vals.whiteText = Calendar.shouldUseWhiteText(vals.highlightColor);

    return SizedBox(
        width: vals.width,
        height: vals.height,
        child: PageView.builder(
          controller: vals.controller,
          reverse: true,
          itemBuilder: (BuildContext context, int page) {
            final index = page - _initialPage;
            // make DateTime for this Month and Year
            int _month = _currentDate.month - index;
            int _year = _currentDate.year;
            while (_month < 1) {
              _month += 12;
              _year--;
            }

            debugPrint(_month.toString() + " " + _year.toString() + " " + index.toString());

            // make highlighted list
            final thisDate = DateTime(_year, _month);
            List<bool> highlights = vals.highlighter(thisDate);

            return _MonthPage(thisDate, highlights, vals);
          },
        ));
  }
}

class _MonthPage extends StatelessWidget {
  final DateTime _dateTime; // DateTime for the first day of the current month
  final List<bool>
  _highlighted; // list indicating which days of the month to highlight
  final _Values vals;

  _MonthPage(DateTime dateTime, this._highlighted, this.vals)
      : this._dateTime = DateTime(dateTime.year,
      dateTime.month); // to make sure it's first day of the month

  @override
  Widget build(BuildContext context) {
    // first row: two arrows on the ends, current month in the middle
    final formatter = DateFormat('MMMM y');
    final row1 = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      // put all space between the children to push arrows to the edges
      children: <Widget>[
        IconButton(
            icon: Icon(Icons.keyboard_arrow_left),
            onPressed: () {
              vals.controller.nextPage(
                  duration: Duration(milliseconds: 500),
                  curve: Curves.decelerate);
            }),
        Text(
          formatter.format(_dateTime),
          style: Theme.of(context)
              .textTheme
              .headline, // set month title to headline style
        ),
        IconButton(
            icon: Icon(Icons.keyboard_arrow_right),
            onPressed: () {
              vals.controller.previousPage(
                  duration: Duration(milliseconds: 500),
                  curve: Curves.decelerate);
            }),
      ],
    );

    // second row: row for days of the week
    final List<String> _daysOfTheWeek = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final row2 = Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly, // evenly space the days
      children: List<Widget>.generate(
      7,
          (index) => Container(
        width: vals.itemSize,
        alignment: Alignment.center,
        child: Text(
          _daysOfTheWeek[index],
          style: TextStyle(fontWeight: FontWeight.bold), // bold the days
        ),
      ),
    ),
    );

    // list of rows for the actual days
    List<Widget> rows = List();

    int _dayOfWeek = _dateTime.weekday;

    int _thisMonth = _dateTime.month;

    DateTime _currentDate =
    _dateTime.subtract(Duration(days: (_dayOfWeek % 7)));
    // DateTime for upper left most day in the calendar

    // increase _dateTime to next month for while loop checking purposes
    final _checkDate =
    _dateTime.add(Duration(days: Calendar.monthLength(_dateTime)));

    while (_currentDate.isBefore(_checkDate)) {
    // check that we haven't gotten to the next month yet
    rows.add(Expanded(
    child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: List<_CalendarDay>.generate(7, (index) {
    // check if this day should be greyed out
    bool greyedOut = false;
    if (_currentDate.month != _thisMonth) {
    greyedOut = true;
    }
    // check if this day should be highlighted
    bool highlight = false;
    if (!greyedOut && _highlighted[_currentDate.day]) {
    highlight = true;
    }
    final ret = _CalendarDay(_currentDate, highlight, greyedOut, vals);
    _currentDate = _currentDate.add(Duration(days: 1)); // add a day
    return ret;
    }),
    )));
    }
    // add the first two rows to rows list
    rows = [row1, row2]..addAll(rows);

    return Column(
    children: rows,
    );
  }
}

class _CalendarDay extends StatelessWidget {
  final DateTime _day;
  final bool _highlighted;
  final bool _greyedOut;

  final _Values vals;

  _CalendarDay(this._day, this._highlighted, this._greyedOut, this.vals);

  @override
  Widget build(BuildContext context) {
    // check if the day is highlighted
    BoxDecoration _decoration;
    if (_highlighted) {
      _decoration = BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        color: vals.highlightColor, // color to theme's accent color
      );
    } else {
      _decoration = BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        color: Colors.transparent,
      );
    }

    // check if this day should be greyed out
    Text _text = Text(
      "${_day.day}",
    );
    if (_greyedOut) {
      _text = Text(
        "${_day.day}",
        style: TextStyle(color: Colors.grey[500]),
      );
    } else if (_highlighted && vals.whiteText){ // check if text color should be white
      _text = Text(
        "${_day.day}",
        style: TextStyle(color: Colors.white),
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      return Container(
          decoration: _decoration,
          child: Material(
            child: InkWell(
              onTap: () {
                vals.onTapListener(_day);
              },
              borderRadius: BorderRadius.circular(100),
              // 100 picked arbitrarily to make circular border
              child: Container(
                //decoration: _decoration,
                height: vals.itemSize,
                width: vals.itemSize,
                alignment: Alignment.center,
                child: _text,
              ),
            ),
            color: Colors.transparent,
          ));
    });
  }
}
