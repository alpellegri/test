import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'drawer.dart';
import 'io_entry.dart';
import 'const.dart';

class FunctionListItem extends StatelessWidget {
  final FunctionEntry entry;

  FunctionListItem(this.entry);

  @override
  Widget build(BuildContext context) {
    return new Padding(
      padding: new EdgeInsets.symmetric(horizontal: 6.0, vertical: 6.0),
      child: new Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          new Expanded(
            child: new Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                new Column(
                  children: [
                    new Text(
                      '${entry.name}',
                      textScaleFactor: 1.5,
                      textAlign: TextAlign.left,
                    ),
                    new Text(
                      'type: ${entry.typeName}',
                      textScaleFactor: 1.0,
                      textAlign: TextAlign.left,
                      style: new TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    new Text(
                      'action name: ${entry.actionName}',
                      textScaleFactor: 1.0,
                      textAlign: TextAlign.left,
                      style: new TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    new Text(
                      'type ID: ${entry.idType}',
                      textScaleFactor: 1.0,
                      textAlign: TextAlign.left,
                      style: new TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    new Text(
                      'action ID: ${entry.idAction}',
                      textScaleFactor: 1.0,
                      textAlign: TextAlign.left,
                      style: new TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    new Text(
                      'delay: ${entry.delay.toString()}',
                      textScaleFactor: 1.0,
                      textAlign: TextAlign.left,
                      style: new TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    new Text(
                      'next: ${entry.next}',
                      textScaleFactor: 1.0,
                      textAlign: TextAlign.left,
                      style: new TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Functions extends StatefulWidget {
  Functions({Key key, this.title}) : super(key: key);

  static const String routeName = '/functions';

  final String title;

  @override
  _FunctionsState createState() => new _FunctionsState();
}

class _FunctionsState extends State<Functions> {
  final DatabaseReference _controlRef =
      FirebaseDatabase.instance.reference().child(kControlRef);

  List<FunctionEntry> entrySaves = new List();
  DatabaseReference _entryRef;

  _FunctionsState() {
    _entryRef = FirebaseDatabase.instance.reference().child(kFunctionsRef);
    _entryRef.onChildAdded.listen(_onEntryAdded);
    _entryRef.onChildChanged.listen(_onEntryEdited);
    _entryRef.onChildRemoved.listen(_onEntryRemoved);
  }

  @override
  void initState() {
    super.initState();
    print('_FunctionsState');
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      drawer: drawer,
      appBar: new AppBar(
        title: new Text(widget.title),
      ),
      body: new ListView.builder(
        shrinkWrap: true,
        reverse: true,
        itemCount: entrySaves.length,
        itemBuilder: (buildContext, index) {
          return new InkWell(
              onTap: () => _openEntryDialog(entrySaves[index]),
              child: new FunctionListItem(entrySaves[index]));
        },
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: _onFloatingActionButtonPressed,
        tooltip: 'add',
        child: new Icon(Icons.add),
      ),
    );
  }

  _onEntryAdded(Event event) {
    setState(() {
      entrySaves.add(new FunctionEntry.fromSnapshot(_entryRef, event.snapshot));
    });
  }

  _onEntryEdited(Event event) {
    FunctionEntry oldValue =
        entrySaves.singleWhere((entry) => entry.key == event.snapshot.key);
    setState(() {
      entrySaves[entrySaves.indexOf(oldValue)] =
          new FunctionEntry.fromSnapshot(_entryRef, event.snapshot);
    });
  }

  _onEntryRemoved(Event event) {
    FunctionEntry oldValue =
        entrySaves.singleWhere((entry) => entry.key == event.snapshot.key);
    setState(() {
      entrySaves.remove(oldValue);
    });
  }

  void _openEntryDialog(FunctionEntry entry) {
    showDialog(
      context: context,
      child: new EntryDialog(entry, entrySaves),
    );
  }

  void _onFloatingActionButtonPressed() {
    FunctionEntry entry = new FunctionEntry(_entryRef);
    _openEntryDialog(entry);
  }
}

class EntryDialog extends StatefulWidget {
  final FunctionEntry entry;
  final List<FunctionEntry> functionSaves;

  EntryDialog(this.entry, this.functionSaves);

  @override
  _EntryDialogState createState() =>
      new _EntryDialogState(entry, functionSaves);
}

class _EntryDialogState extends State<EntryDialog> {
  final TextEditingController _controllerName = new TextEditingController();
  final TextEditingController _controllerDelay = new TextEditingController();
  final FunctionEntry entry;
  final List<FunctionEntry> functionSaves;

  String _selectType;
  String _selectAction;
  int _selectIdAction;
  String _selectDelay;
  String _selectNext;
  List<String> selectTypeMenu = new List();
  Map<String, List> _selectedSaves = new Map();
  List ioMenu;
  dynamic _selectedElem;
  Map<String, int> _mapType = {
    'DOUT': 1,
    'Radio Tx': 2,
    'LOUT': 3,
  };

  List<RadioCodeEntry> radioTxSaves = new List();
  DatabaseReference _radioTxRef;
  List<IoEntry> doutSaves = new List();
  DatabaseReference _doutRef;
  List<IoEntry> loutSaves = new List();
  DatabaseReference _loutRef;

  _EntryDialogState(this.entry, this.functionSaves) {
    print('EntryDialogState');
    _radioTxRef = FirebaseDatabase.instance
        .reference()
        .child(kRadioCodesRef)
        .child('ActiveTx');
    _radioTxRef.onChildAdded.listen(_onRadioEntryAdded);
    _doutRef = FirebaseDatabase.instance.reference().child(kDoutRef);
    _doutRef.onChildAdded.listen(_onDoutEntryAdded);
    _loutRef = FirebaseDatabase.instance.reference().child(kLoutRef);
    _loutRef.onChildAdded.listen(_onLoutEntryAdded);

    _selectedSaves['DOUT'] = doutSaves;
    _selectedSaves['LOUT'] = loutSaves;
    _selectedSaves['Radio Tx'] = radioTxSaves;
    _selectedSaves.forEach((String key, List value) {
      selectTypeMenu.add(key);
    });

    _controllerName.text = entry.name;
    _controllerDelay.text = entry.delay.toString();
    _selectType = entry.typeName;
    ioMenu = _selectedSaves[_selectType];
    _selectAction = entry.actionName;
    _selectNext = entry.next;
  }

  @override
  Widget build(BuildContext context) {
    return new AlertDialog(
        title: new Text('Edit a Function'),
        content: new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              new TextField(
                controller: _controllerName,
                decoration: new InputDecoration(
                  hintText: 'Name',
                ),
              ),
              new ListTile(
                title: const Text('Action Type'),
                trailing: new DropdownButton<String>(
                  hint: const Text('select a type'),
                  value: _selectType,
                  onChanged: (String newValue) {
                    setState(() {
                      _selectType = newValue;
                      ioMenu = _selectedSaves[_selectType];
                      _selectAction = null;
                    });
                  },
                  items: selectTypeMenu.map((String entry) {
                    return new DropdownMenuItem<String>(
                      value: entry,
                      child: new Text(
                        entry,
                      ),
                    );
                  }).toList(),
                ),
              ),
              (ioMenu.length > 0)
                  ? new ListTile(
                      title: const Text('Action'),
                      trailing: new DropdownButton<dynamic>(
                        hint: const Text('select an action'),
                        value: _selectedElem,
                        onChanged: (dynamic newValue) {
                          setState(() {
                            _selectedElem = newValue;
                            _selectIdAction = newValue.id;
                          });
                        },
                        items: ioMenu.map((dynamic entry) {
                          return new DropdownMenuItem<dynamic>(
                            value: entry,
                            child: new Text(
                              entry.name,
                            ),
                          );
                        }).toList(),
                      ),
                    )
                  : new Text('Actions not declared yet'),
              new TextField(
                controller: _controllerDelay,
                decoration: new InputDecoration(
                  hintText: 'delay',
                ),
              ),
              (functionSaves.length > 0)
                  ? new ListTile(
                      title: const Text('Next Function'),
                      trailing: new DropdownButton<String>(
                        hint: const Text('Select a Function'),
                        value: _selectNext,
                        onChanged: (String newValue) {
                          setState(() {
                            _selectNext = newValue;
                          });
                        },
                        items: functionSaves.map((FunctionEntry entry) {
                          return new DropdownMenuItem<String>(
                            value: entry.name,
                            child: new Text(
                              entry.name,
                            ),
                          );
                        }).toList(),
                      ),
                    )
                  : new Text('Functions not declared yet'),
            ]),
        actions: <Widget>[
          new FlatButton(
              child: const Text('REMOVE'),
              onPressed: () {
                entry.reference.child(entry.key).remove();
                Navigator.pop(context, null);
              }),
          new FlatButton(
              child: const Text('SAVE'),
              onPressed: () {
                try {
                  int delay = int.parse(_controllerDelay.text);
                  setState(() {
                    entry.delay = delay;
                    entry.name = _controllerName.text;
                    entry.next = _selectNext;
                    entry.typeName = _selectType;
                    // dynamic element = ioMenu.singleWhere((entry) => entry.key == _selectAction);
                    entry.idType = _mapType[_selectType];
                    entry.idAction = _selectIdAction;
                    entry.actionName = _selectAction;
                    if (entry.key != null) {
                      entry.reference.child(entry.key).remove();
                    }
                    entry.reference.push().set(entry.toJson());
                  });
                } catch (exception, stackTrace) {}

                Navigator.pop(context, null);
              }),
          new FlatButton(
              child: const Text('DISCARD'),
              onPressed: () {
                Navigator.pop(context, null);
              }),
        ]);
  }

  _onRadioEntryAdded(Event event) {
    setState(() {
      radioTxSaves
          .add(new RadioCodeEntry.fromSnapshot(_radioTxRef, event.snapshot));
    });
  }

  _onDoutEntryAdded(Event event) {
    setState(() {
      doutSaves.add(new IoEntry.fromSnapshot(_doutRef, event.snapshot));
    });
  }

  _onLoutEntryAdded(Event event) {
    setState(() {
      loutSaves.add(new IoEntry.fromSnapshot(_loutRef, event.snapshot));
    });
  }
}
