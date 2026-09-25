import 'package:flutter/material.dart';

import '../widgets/calendar_panel_widget.dart';
import 'task_form_screen.dart';

class TaskCalendarScreen extends StatelessWidget {
  const TaskCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalender Tugas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Tambah Tugas',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => TaskFormScreen(
                  initialDeadline: DateTime.now(),
                ),
              );
            },
          ),
        ],
      ),
      body: const SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(bottom: 80),
          child: CalendarPanelWidget(
            showHeaderTitle: false,
            maxTasksPreview: 50,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => TaskFormScreen(
              initialDeadline: DateTime.now(),
            ),
          );
        },
        tooltip: 'Tambah Tugas',
        child: const Icon(Icons.add),
      ),
    );
  }
}
