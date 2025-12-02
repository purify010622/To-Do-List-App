# Contributing to Todo App

Thank you for considering contributing to this project! 🎉

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/todo-app.git`
3. Create a branch: `git checkout -b feature/your-feature-name`
4. Make your changes
5. Test your changes
6. Commit: `git commit -m 'Add some feature'`
7. Push: `git push origin feature/your-feature-name`
8. Open a Pull Request

## Development Setup

### Backend
```bash
cd backend
npm install
copy .env.example .env
# Edit .env with your credentials
npm run dev
```

### Flutter App
```bash
cd todo_app_offline_sync
flutter pub get
flutter run
```

## Code Style

### Backend (Node.js)
- Use ES6+ features
- Follow ESLint configuration
- Write meaningful commit messages
- Add tests for new features

### Flutter (Dart)
- Follow Dart style guide
- Use `flutter format` before committing
- Run `flutter analyze` to check for issues
- Write widget tests for UI components

## Testing

### Backend Tests
```bash
cd backend
npm test
```

### Flutter Tests
```bash
cd todo_app_offline_sync
flutter test
```

## Pull Request Guidelines

1. **Keep PRs focused** - One feature/fix per PR
2. **Write clear descriptions** - Explain what and why
3. **Add tests** - For new features and bug fixes
4. **Update documentation** - If you change APIs or features
5. **Follow code style** - Run linters before submitting
6. **Keep commits clean** - Squash if needed

## Commit Message Format

```
type(scope): subject

body (optional)

footer (optional)
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

Examples:
```
feat(backend): add task filtering by priority
fix(flutter): resolve sync conflict issue
docs(readme): update installation instructions
```

## Security

- Never commit credentials or API keys
- Review [SECURITY.md](SECURITY.md) before contributing
- Report security vulnerabilities privately

## Questions?

- Open an issue for bugs or feature requests
- Check existing issues before creating new ones
- Be respectful and constructive in discussions

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
