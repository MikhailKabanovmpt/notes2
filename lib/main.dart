import 'package:flutter/material.dart';

void main() {
  runApp(const NotesApp());
}

class Note {
  Note(this.text, {this.isImportant = false});

  String text;
  bool isImportant;
}

class NotesApp extends StatelessWidget {
  const NotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Заметки',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const NotesPage(),
    );
  }
}

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  static const double _swipeVelocity = 300;

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final List<Note> _notes = [];
  int? _editingIndex;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _save() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      if (_editingIndex == null) {
        _notes.add(Note(text));
      } else {
        _notes[_editingIndex!].text = text;
        _editingIndex = null;
      }
      _controller.clear();
    });
    FocusScope.of(context).unfocus();
  }

  void _startEdit(int index) {
    setState(() {
      _editingIndex = index;
      _controller.text = _notes[index].text;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    });
    _focusNode.requestFocus();
  }

  void _cancelEdit() {
    setState(() {
      _editingIndex = null;
      _controller.clear();
    });
    FocusScope.of(context).unfocus();
  }

  void _delete(int index) {
    setState(() {
      _notes.removeAt(index);
      if (_editingIndex == index) {
        _editingIndex = null;
        _controller.clear();
      } else if (_editingIndex != null && _editingIndex! > index) {
        _editingIndex = _editingIndex! - 1;
      }
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Заметка удалена'),
          duration: Duration(seconds: 2),
        ),
      );
  }

  void _toggleImportant(int index) {
    setState(() {
      _notes[index].isImportant = !_notes[index].isImportant;
    });
  }

  void _restore(int index) {
    if (!_notes[index].isImportant) return;
    setState(() {
      _notes[index].isImportant = false;
    });
  }

  void _showNote(int index) {
    final note = _notes[index];
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              if (note.isImportant) ...[
                const Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 8),
              ],
              const Text('Заметка'),
            ],
          ),
          content: SingleChildScrollView(child: Text(note.text)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Закрыть'),
            ),
          ],
        );
      },
    );
  }

  void _onHorizontalDragEnd(int index, DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -_swipeVelocity) {
      _delete(index);
    } else if (velocity > _swipeVelocity) {
      _restore(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _editingIndex != null;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Заметки')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: isEditing ? 'Редактирование заметки' : 'Введите текст',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    child: Text(isEditing ? 'Обновить' : 'Сохранить'),
                  ),
                ),
                if (isEditing) ...[
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: _cancelEdit,
                    child: const Text('Отмена'),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _notes.isEmpty
                  ? const Center(child: Text('Заметок пока нет'))
                  : ListView.builder(
                      itemCount: _notes.length,
                      itemBuilder: (context, index) {
                        final note = _notes[index];
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _showNote(index),
                          onDoubleTap: () => _toggleImportant(index),
                          onLongPress: () => _startEdit(index),
                          onHorizontalDragEnd: (details) =>
                              _onHorizontalDragEnd(index, details),
                          child: Card(
                            color: note.isImportant
                                ? colors.secondaryContainer
                                : null,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: _editingIndex == index
                                  ? BorderSide(color: colors.primary, width: 2)
                                  : BorderSide.none,
                            ),
                            child: ListTile(
                              title: Text(
                                note.text,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: note.isImportant
                                  ? const Icon(Icons.star, color: Colors.amber)
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
