import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Comments',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const CommentPage(),
    );
  }
}

class Comment {
  final int start;
  final int end;
  final String text;
  final String comment;
  final String user;

  Comment({
    required this.start,
    required this.end,
    required this.text,
    required this.comment,
    required this.user,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      start: json['start_index'],
      end: json['end_index'],
      text: json['selected_text'],
      comment: json['comment_text'],
      user: json['user_name'],
    );
  }
}

class CommentPage extends StatefulWidget {
  const CommentPage({super.key});

  @override
  State<CommentPage> createState() => _CommentPageState();
}

class _CommentPageState extends State<CommentPage> {
  final String paragraph = """
      HI!!, This is Kavya Chokkalingam.
      I made this Flutter Application.
      This is a sample paragraph. 
      You can select any part of this text and add a comment to check.
      """;
  final TextEditingController _commentController = TextEditingController();
  List<Comment> comments = [];

  TextSelection? selection;
  Offset? selectionOffset;

  @override
  void initState() {
    super.initState();
    fetchComments();
  }

  Future<void> fetchComments() async {
    final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/comments?paragraph_id=1'));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      setState(() {
        comments = data.map((e) => Comment.fromJson(e)).toList();
      });
    }
  }

  Future<void> postComment(int start, int end, String selectedText) async {
    final text = _commentController.text; 
    if (text.isEmpty) return;

    final response = await http.post(
      Uri.parse('http://127.0.0.1:8000/comments'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'paragraph_id': 1,
        'start_index': start,
        'end_index': end,
        'selected_text': selectedText,
        'comment_text': text,
        'user_name': 'Kavya'
      }),
    );

    if (response.statusCode == 200) {
      _commentController.clear();
      setState(() {
        selection = null;
        selectionOffset = null;
      });
      fetchComments();
    }
  }

  void _showFloatingCommentDialog() {
    if (selection == null || selection!.start == selection!.end) return;
    final selectedText = paragraph.substring(selection!.start, selection!.end);

    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text("Add Comment"),
              content: TextField(
                controller: _commentController,
                decoration:
                    const InputDecoration(hintText: "Enter your comment"),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel")),
                ElevatedButton(
                    onPressed: () {
                      postComment(selection!.start, selection!.end, selectedText);
                      Navigator.pop(context);
                    },
                    child: const Text("Add"))
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    List<TextSpan> spans = [];
    int lastIndex = 0;

    for (final c in comments) {
      if (c.start > lastIndex) {
        spans.add(TextSpan(
            text: paragraph.substring(lastIndex, c.start),
            style: const TextStyle(color: Colors.black)));
      }
      spans.add(TextSpan(
          text: paragraph.substring(c.start, c.end),
          style: const TextStyle(backgroundColor: Colors.yellow)));
      lastIndex = c.end;
    }

    if (lastIndex < paragraph.length) {
      spans.add(TextSpan(
          text: paragraph.substring(lastIndex),
          style: const TextStyle(color: Colors.black)));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Flutter Comments App")),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Expanded(
                  child: SelectableText.rich(
                    TextSpan(children: spans, style: const TextStyle(fontSize: 18)),
                    onSelectionChanged: (sel, cause) {
                      RenderBox box = context.findRenderObject() as RenderBox;
                      final offset = box.localToGlobal(Offset.zero);
                      setState(() {
                        selection = sel;
                        selectionOffset = offset + const Offset(0, 0);
                      });
                    },
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final c = comments[index];
                      return ListTile(
                        title: Text(c.comment),
                        subtitle:
                            Text("Text: '${c.text}' - by ${c.user}"),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Floating button near selection for comment option
          if (selection != null && selection!.start != selection!.end)
            Positioned(
              top: selectionOffset?.dy ?? 50,
              left: selectionOffset?.dx ?? 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_comment),
                label: const Text("Add Comment"),
                onPressed: _showFloatingCommentDialog,
              ),
            ),
        ],
      ),
    );
  }
}
